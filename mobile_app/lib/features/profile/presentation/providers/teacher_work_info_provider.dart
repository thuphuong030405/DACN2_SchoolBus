import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/profile/data/models/teacher_work_info_model.dart';
import 'package:mobile_app/features/profile/domain/entities/teacher_work_info.dart';

/// Chạy một truy vấn, nếu lỗi thì in rõ truy vấn nào lỗi rồi ném lại.
Future<T> _step<T>(String name, Future<T> Function() run) async {
  try {
    return await run();
  } catch (e) {
    debugPrint('❌ [teacherWorkInfo] "$name" lỗi: $e');
    rethrow;
  }
}

final teacherWorkInfoProvider =
    FutureProvider.autoDispose<TeacherWorkInfo>((ref) async {
  final client = Supabase.instance.client;
  final uid = client.auth.currentUser?.id;
  if (uid == null) return const TeacherWorkInfo();

  // 1. Hồ sơ giáo viên
  final teacher = await _step('1. teachers', () {
    return client
        .from('teachers')
        .select('teacher_id, teacher_code')
        .eq('user_id', uid)
        .maybeSingle();
  });

  if (teacher == null) {
    debugPrint('⚠️ [teacherWorkInfo] Không có dòng teachers cho user $uid '
        '(chưa tạo hồ sơ giáo viên, hoặc RLS chặn)');
    return const TeacherWorkInfo();
  }

  final teacherId = teacher['teacher_id'] as String;

  // 2. Các chuyến đã hoàn thành
  final completed = await _step('2. trips COMPLETED', () {
    return client
        .from('trips')
        .select('trip_id')
        .eq('teacher_id', teacherId)
        .eq('status', 'COMPLETED');
  });

  final completedIds = completed.map((e) => e['trip_id']).toList();

  // 3. Số chuyến có cảnh báo trễ
  var delayedTrips = 0;
  if (completedIds.isNotEmpty) {
    final delayed = await _step('3. alerts TRIP_DELAY', () {
      return client
          .from('alerts')
          .select('trip_id')
          .eq('alert_type', 'TRIP_DELAY')
          .inFilter('trip_id', completedIds);
    });
    delayedTrips = delayed.map((e) => e['trip_id']).toSet().length;
  }

  // 4. Sự cố / cảnh báo thủ công do chính giáo viên gửi
  final incidents = await _step('4. alerts do giáo viên gửi', () {
    return client
        .from('alerts')
        .select('alert_id')
        .eq('reported_by', uid)
        .inFilter('alert_type', ['MANUAL_ALERT', 'INCIDENT']);
  });

  // 5. Chuyến gần nhất đã bắt đầu (bỏ chuyến đã hủy),
  //    kèm xe, tuyến, tài xế và hạn bằng lái của tài xế
  final currentTrip = await _step('5. chuyến hiện tại', () {
    return client
        .from('trips')
        .select(
          'trip_id, buses(license_plate), routes(route_name), '
          'drivers(license_expiry, users(full_name))',
        )
        .eq('teacher_id', teacherId)
        .neq('status', 'CANCELLED')
        .lte('start_at', DateTime.now().toUtc().toIso8601String())
        .order('start_at', ascending: false)
        .limit(1)
        .maybeSingle();
  });

  return TeacherWorkInfoModel.fromParts(
    teacherCode: teacher['teacher_code'] as String?,
    completedTrips: completed.length,
    reportedIncidents: incidents.length,
    delayedTrips: delayedTrips,
    currentTrip: currentTrip,
  );
});