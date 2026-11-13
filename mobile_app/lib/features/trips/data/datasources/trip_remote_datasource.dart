import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/trips/data/models/teacher_trip_model.dart';
import 'package:mobile_app/features/trips/data/models/trip_route_detail_model.dart';

class TripRemoteDataSource {
  final SupabaseClient client;

  const TripRemoteDataSource(this.client);

  /// Ngày hiện tại theo giờ Việt Nam (khớp CHECK trip_date trong DB).
  String _todayVn() {
    final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
    return '${vn.year.toString().padLeft(4, '0')}-'
        '${vn.month.toString().padLeft(2, '0')}-'
        '${vn.day.toString().padLeft(2, '0')}';
  }

  Future<List<TeacherTripModel>> getTeacherTodayTrips(
    String authUserId,
  ) async {
    final today = _todayVn();

    // trips -> teachers (lọc theo user_id), routes, buses
    final rows = await client
        .from('trips')
        .select('''
          trip_id, trip_date, trip_type, start_at, end_at, status, route_id,
          routes ( route_code, route_name ),
          buses ( license_plate ),
          teachers!inner ( user_id )
        ''')
        .eq('teachers.user_id', authUserId)
        .eq('trip_date', today)
        .neq('status', 'CANCELLED')
        .order('start_at', ascending: true);

    final trips = List<Map<String, dynamic>>.from(rows);

    // Đếm học sinh cho từng chuyến (thường chỉ 2-4 chuyến/ngày)
    return Future.wait(trips.map((json) async {
      final counts = await Future.wait([
        _countStudentsOnRoute(json['route_id'] as String, today),
        _countProcessedAttendance(json['trip_id'] as String),
      ]);

      return TeacherTripModel.fromJson(
        json,
        totalStudents: counts[0],
        attendedStudents: counts[1],
      );
    }));
  }

  /// Tổng số học sinh được phân vào tuyến (còn hiệu lực trong ngày).
  Future<int> _countStudentsOnRoute(String routeId, String date) async {
    final res = await client
        .from('student_routes')
        .select('student_route_id')
        .eq('route_id', routeId)
        .eq('status', 'ACTIVE')
        .lte('effective_from', date)
        .or('effective_to.is.null,effective_to.gte.$date')
        .count(CountOption.exact);

    return res.count;
  }

  /// Số học sinh đã được điểm danh (khác PENDING) trong chuyến.
  Future<int> _countProcessedAttendance(String tripId) async {
    final res = await client
        .from('attendance')
        .select('attendance_id')
        .eq('trip_id', tripId)
        .neq('status', 'PENDING')
        .count(CountOption.exact);

    return res.count;
  }

  /// Chọn chuyến: đang chạy > sắp tới (sớm nhất) > chuyến cuối trong ngày.
  Future<TripRouteDetailModel?> getTeacherCurrentTripRoute(
    String authUserId,
  ) async {
    final today = _todayVn();

    final rows = await client
        .from('trips')
        .select('''
          trip_id, trip_type, start_at, end_at, status, route_id,
          routes ( route_code, route_name ),
          buses ( license_plate ),
          teachers!inner ( user_id )
        ''')
        .eq('teachers.user_id', authUserId)
        .eq('trip_date', today)
        .neq('status', 'CANCELLED')
        .order('start_at', ascending: true);

    final trips = List<Map<String, dynamic>>.from(rows);
    if (trips.isEmpty) return null;

    final trip = trips.firstWhere(
      (t) => t['status'] == 'IN_PROGRESS',
      orElse: () => trips.firstWhere(
        (t) => t['status'] == 'SCHEDULED',
        orElse: () => trips.last,
      ),
    );

    final stopRows = await client
        .from('route_stops')
        .select(
          'stop_id, stop_name, address, stop_order, estimated_time, '
          'latitude, longitude',
        )
        .eq('route_id', trip['route_id'] as String)
        .eq('is_active', true)
        .order('stop_order', ascending: true);

    final stopsJson = List<Map<String, dynamic>>.from(stopRows);

    // Số học sinh theo từng điểm dừng (đếm theo student_id,
    // nên chị em sinh đôi cùng điểm vẫn tính là 2 học sinh).
    final studentCounts = await _getStudentCountsByStop(
      stopsJson,
      trip['trip_type'] as String,
    );

    // Vị trí GPS của xe (chỉ cần khi chuyến đang chạy)
    final gpsPoints = trip['status'] == 'IN_PROGRESS'
        ? await _getGpsPoints(trip['trip_id'] as String)
        : <(double, double)>[];

    return TripRouteDetailModel.fromJson(
      trip,
      stopsJson,
      gpsPoints: gpsPoints,
      studentCounts: studentCounts,
    );
  }

  /// stopId -> số học sinh đón/trả tại điểm đó cho loại chuyến [tripType].
  Future<Map<String, int>> _getStudentCountsByStop(
    List<Map<String, dynamic>> stopsJson,
    String tripType,
  ) async {
    final stopIds = stopsJson.map((s) => s['stop_id'] as String).toList();
    if (stopIds.isEmpty) return const {};

    final rows = await client
        .from('student_stops')
        .select('student_id, stop_id')
        .eq('trip_type', tripType)
        .inFilter('stop_id', stopIds);

    return TripRouteDetailModel.countStudentsByStop(
      List<Map<String, dynamic>>.from(rows),
    );
  }

  /// Toạ độ GPS của chuyến, sắp xếp CŨ -> MỚI
  /// (phần tử cuối là vị trí hiện tại của xe).
  Future<List<(double, double)>> _getGpsPoints(String tripId) async {
    final rows = await client
        .from('gps_locations')
        .select('latitude, longitude')
        .eq('trip_id', tripId)
        .order('recorded_at', ascending: false)
        .limit(1000);

    // Query lấy mới -> cũ nên đảo lại.
    return List<Map<String, dynamic>>.from(rows)
        .map((g) => (
              (g['latitude'] as num).toDouble(),
              (g['longitude'] as num).toDouble(),
            ))
        .toList()
        .reversed
        .toList();
  }
}