import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lưu JSON vào bộ nhớ riêng của app.
class OfflineStore {
  static String _safe(String k) {
    final s = k.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
    return s.length > 120 ? s.substring(0, 120) : s;
  }

  static Future<File> _file(String key) async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/offline_${_safe(key)}.json');
  }

  static Future<void> put(String key, Object? value) async {
    final f = await _file(key);
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(jsonEncode(value), flush: true);
    await tmp.rename(f.path);
  }

  static Future<dynamic> get(String key) async {
    try {
      final f = await _file(key);
      if (!await f.exists()) return null;
      return jsonDecode(await f.readAsString());
    } catch (e) {
      debugPrint('OfflineStore.get($key): $e');
      return null;
    }
  }

  static Future<void> removePrefix(String prefix) async {
    final dir = await getApplicationSupportDirectory();
    final p = 'offline_${_safe(prefix)}';
    for (final e in dir.listSync()) {
      if (e is File && e.uri.pathSegments.last.startsWith(p)) {
        try {
          await e.delete();
        } catch (_) {}
      }
    }
  }

  /// Sửa các dòng có [idKey] == [idVal] trong mọi bộ nhớ đệm bắt đầu bằng [prefix].
  static Future<void> patchWhere(
    String prefix,
    String idKey,
    Object? idVal,
    Map<String, dynamic> values,
  ) async {
    final dir = await getApplicationSupportDirectory();
    final p = 'offline_${_safe(prefix)}';
    for (final e in dir.listSync()) {
      if (e is! File || !e.uri.pathSegments.last.startsWith(p)) continue;
      try {
        final raw = jsonDecode(await e.readAsString());
        var changed = false;
        if (raw is List) {
          for (final r in raw) {
            if (r is Map && r[idKey] == idVal) {
              r.addAll(values);
              changed = true;
            }
          }
        }
        if (changed) await e.writeAsString(jsonEncode(raw), flush: true);
      } catch (_) {}
    }
  }

  /// Danh sách điểm danh của 1 chuyến.
  /// Có mạng và không còn lệnh chờ -> lấy từ server và lưu lại.
  /// Mất mạng (hoặc còn lệnh chờ đẩy) -> dùng bản trong máy.
  /// [preferCache] = true: có bản trong máy là dùng luôn (nhanh, dùng khi quét mặt).
  static Future<List<Map<String, dynamic>>> roster({
    required String tripId,
    required String name,
    required Future<dynamic> Function() fetch,
    bool preferCache = false,
  }) async {
    final key = 'roster_${name}_$tripId';

    Future<List<Map<String, dynamic>>?> readCache() async {
      final c = await get(key);
      if (c is! List) return null;
      return c.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    if (preferCache) {
      final c = await readCache();
      if (c != null) return c;
    }

    await SyncService.flush();
    if (await SyncService.pendingNow() == 0) {
      try {
        final data = await fetch().timeout(const Duration(seconds: 8));
        final list = (data as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await put(key, list);
        return list;
      } catch (e) {
        debugPrint('Roster offline, dùng bản lưu: $e');
      }
    }

    final c = await readCache();
    if (c != null) return c;
    throw Exception(
      'Chưa có dữ liệu offline. Hãy mở chuyến này khi có mạng ít nhất một lần.',
    );
  }
}

/// Hàng đợi các lệnh UPDATE chờ đẩy lên Supabase.
class SyncService {
  static const _qKey = 'pending_queue';
  static const _failedKey = 'failed_queue';
  static bool _running = false;
  static Timer? _timer;

  /// Số lệnh đang chờ đồng bộ (dùng để hiện thông báo nếu muốn).
  static final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  static Future<void> _lock = Future.value();
  static Future<T> _sync<T>(Future<T> Function() fn) {
    final result = _lock.then((_) => fn());
    _lock = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  static Future<List<Map<String, dynamic>>> _load() async {
    final raw = await OfflineStore.get(_qKey);
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<void> _save(List<Map<String, dynamic>> q) async {
    await OfflineStore.put(_qKey, q);
    pendingCount.value = q.length;
  }

  static Future<int> pendingNow() async => (await _sync(_load)).length;

  /// Gọi 1 lần ở main.dart sau Supabase.initialize.
  static void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => flush());
    pendingNow().then((n) => pendingCount.value = n);
    flush();
  }

  static Future<void> enqueueUpdate({
    required String table,
    required Map<String, dynamic> values,
    required String matchColumn,
    required String matchValue,
  }) {
    return _sync(() async {
      final q = await _load();
      q.add({
        'id': '${DateTime.now().microsecondsSinceEpoch}',
        'table': table,
        'values': values,
        'match_col': matchColumn,
        'match_val': matchValue,
      });
      await _save(q);
    });
  }

  static Future<void> _removeFirst(String id, {String? error}) {
    return _sync(() async {
      final q = await _load();
      final idx = q.indexWhere((e) => e['id'] == id);
      if (idx < 0) return;
      final item = q.removeAt(idx);
      if (error != null) {
        final raw = await OfflineStore.get(_failedKey);
        final failed = raw is List ? List<dynamic>.from(raw) : <dynamic>[];
        failed.add({...item, 'error': error});
        await OfflineStore.put(_failedKey, failed);
      }
      await _save(q);
    });
  }

  static bool _isAuthError(PostgrestException e) =>
      e.code == 'PGRST301' ||
      e.code == 'PGRST303' ||
      e.message.toLowerCase().contains('jwt');

  /// Đẩy lần lượt từng lệnh. Gặp lỗi mạng thì dừng, lần sau thử lại.
  static Future<void> flush() async {
    if (_running) return;
    _running = true;
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) return;

      final s = client.auth.currentSession;
      if (s != null && s.isExpired) {
        try {
          await client.auth.refreshSession();
        } catch (_) {
          return; // chưa có mạng để làm mới phiên
        }
      }

      while (true) {
        final q = await _sync(_load);
        pendingCount.value = q.length;
        if (q.isEmpty) return;

        final item = q.first;
        try {
          await client
              .from(item['table'] as String)
              .update(Map<String, dynamic>.from(item['values'] as Map))
              .eq(item['match_col'] as String, item['match_val'] as String)
              .timeout(const Duration(seconds: 10));
          await _removeFirst(item['id'] as String);
        } on PostgrestException catch (e) {
          if (_isAuthError(e)) return; // token hết hạn: giữ lại, thử sau
          // Lỗi nghiệp vụ (vd: vi phạm quy tắc điểm danh): bỏ vào failed_queue
          debugPrint('Sync bị từ chối: ${e.message}');
          await _removeFirst(item['id'] as String, error: e.message);
        } catch (_) {
          return; // mất mạng / timeout
        }
      }
    } finally {
      _running = false;
    }
  }
}