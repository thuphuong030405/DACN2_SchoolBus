import 'package:flutter/foundation.dart';
import 'package:mobile_app/core/offline/offline_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Nguồn DUY NHẤT để lấy "chuyến đang chạy" của giáo viên đang đăng nhập.
/// Trang chủ, tab Điểm danh và nút camera đều dùng hàm này nên luôn khớp nhau.
/// Có mạng: lấy từ server và lưu lại. Mất mạng: dùng bản đã lưu.
class ActiveTripQuery {
  static Future forCurrentTeacher(
    SupabaseClient client, {
    String columns =
        'trip_id, status, trip_type, start_at, routes(route_name), buses(license_plate)',
  }) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) return null;

    final cacheKey = 'active_trip_${uid}_$columns';
    try {
      // Trả về null nếu giáo viên chưa được phân công chuyến
      // hoặc có chuyến nhưng chưa bấm "Bắt đầu chuyến".
      final result = await client
          .from('trips')
          .select('$columns, teachers!inner(user_id)')
          .eq('status', 'IN_PROGRESS')
          .eq('teachers.user_id', uid)
          .order('start_at')
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 8));

      await OfflineStore.put(cacheKey, result); // null cũng lưu
      return result;
    } catch (e) {
      debugPrint('ActiveTripQuery offline: $e');

      // 1) Bản lưu riêng của câu truy vấn này
      final cached = await OfflineStore.get(cacheKey);
      if (cached is Map) return Map<String, dynamic>.from(cached);

      // 2) Chưa có: dựng từ danh sách chuyến hôm nay đã lưu
      final trips = await OfflineStore.get('today_trips_$uid');
      if (trips is List) {
        for (final t in trips) {
          if (t is Map && t['status'] == 'IN_PROGRESS') {
            return {
              'trip_id': t['trip_id'],
              'status': t['status'],
              'trip_type': t['trip_type'],
              'start_at': t['start_at'],
              'routes': {'route_name': t['route_name']},
              'buses': {'license_plate': t['license_plate']},
            };
          }
        }
      }
      return null;
    }
  }
}