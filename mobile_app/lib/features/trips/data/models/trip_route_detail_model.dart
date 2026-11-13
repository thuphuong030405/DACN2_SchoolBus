import 'dart:math' as math;

import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';

class TripRouteDetailModel extends TripRouteDetail {
  const TripRouteDetailModel({
    required super.tripId,
    required super.tripType,
    required super.status,
    required super.routeCode,
    required super.routeName,
    required super.licensePlate,
    required super.startAt,
    required super.endAt,
    required super.stops,
    super.busLatitude,
    super.busLongitude,
  });

  /// Xe được coi là đã tới điểm dừng khi có toạ độ GPS cách điểm đó <= bán kính này.
  static const double arrivalRadiusMeters = 100;

  /// [tripJson]: 1 dòng trips kèm routes(...), buses(...)
  /// [stopsJson]: các dòng route_stops của tuyến, đã sắp theo stop_order
  /// [gpsPoints]: các toạ độ (lat, lng) từ gps_locations, CŨ -> MỚI
  ///              (phần tử cuối là vị trí mới nhất của xe)
  /// [studentCounts]: stopId -> số học sinh, tạo bằng [countStudentsByStop]
  factory TripRouteDetailModel.fromJson(
    Map<String, dynamic> tripJson,
    List<Map<String, dynamic>> stopsJson, {
    List<(double, double)> gpsPoints = const [],
    Map<String, int> studentCounts = const {},
  }) {
    final route = tripJson['routes'] as Map<String, dynamic>? ?? const {};
    final bus = tripJson['buses'] as Map<String, dynamic>? ?? const {};
    final tripStatus = tripJson['status'] as String;

    final progresses = _computeProgress(tripStatus, stopsJson, gpsPoints);

    final stops = <RouteStopInfo>[
      for (var i = 0; i < stopsJson.length; i++)
        _stopFromJson(
          stopsJson[i],
          progresses[i],
          studentCounts[stopsJson[i]['stop_id'] as String] ?? 0,
        ),
    ];

    final lastGps = gpsPoints.isNotEmpty ? gpsPoints.last : null;

    return TripRouteDetailModel(
      tripId: tripJson['trip_id'] as String,
      tripType: tripJson['trip_type'] as String,
      status: tripStatus,
      routeCode: route['route_code'] as String? ?? '',
      routeName: route['route_name'] as String? ?? '',
      licensePlate: bus['license_plate'] as String? ?? '',
      startAt: DateTime.parse(tripJson['start_at'] as String).toLocal(),
      endAt: DateTime.parse(tripJson['end_at'] as String).toLocal(),
      stops: stops,
      busLatitude: lastGps?.$1,
      busLongitude: lastGps?.$2,
    );
  }

  /// Đếm số học sinh theo điểm dừng.
  ///
  /// Dùng Set theo student_id: mỗi học sinh chỉ tính 1 lần (tránh đếm trùng
  /// do join), còn anh chị em sinh đôi có student_id khác nhau nên vẫn được
  /// tính là 2 học sinh riêng.
  static Map<String, int> countStudentsByStop(
    List<Map<String, dynamic>> rows,
  ) {
    final byStop = <String, Set<String>>{};
    for (final r in rows) {
      final stopId = r['stop_id'] as String?;
      final studentId = r['student_id'] as String?;
      if (stopId == null || studentId == null) continue;
      byStop.putIfAbsent(stopId, () => <String>{}).add(studentId);
    }
    return {for (final e in byStop.entries) e.key: e.value.length};
  }

  static RouteStopInfo _stopFromJson(
    Map<String, dynamic> s,
    StopProgress progress,
    int studentCount,
  ) {
    final time = s['estimated_time'] as String?; // 'HH:mm:ss'
    return RouteStopInfo(
      stopId: s['stop_id'] as String,
      name: s['stop_name'] as String,
      address: s['address'] as String,
      order: s['stop_order'] as int,
      estimatedTime:
          (time != null && time.length >= 5) ? time.substring(0, 5) : null,
      progress: progress,
      latitude: (s['latitude'] as num?)?.toDouble(),
      longitude: (s['longitude'] as num?)?.toDouble(),
      studentCount: studentCount,
    );
  }

  /// Xác định tiến độ từng điểm dừng dựa trên trạng thái chuyến và GPS:
  /// - COMPLETED: tất cả đã qua
  /// - CANCELLED: tất cả chưa đến, không có điểm tiếp theo
  /// - SCHEDULED: chưa xuất phát, điểm đầu tiên là điểm tiếp theo
  /// - IN_PROGRESS: điểm xa nhất mà GPS đã tới (trong bán kính) và mọi điểm
  ///   trước nó là "đã qua"; điểm kế đó là "tiếp theo"; còn lại "chưa đến"
  static List<StopProgress> _computeProgress(
    String tripStatus,
    List<Map<String, dynamic>> stops,
    List<(double, double)> gps,
  ) {
    final n = stops.length;

    if (tripStatus == 'COMPLETED') {
      return List.filled(n, StopProgress.passed);
    }
    if (tripStatus == 'CANCELLED') {
      return List.filled(n, StopProgress.upcoming);
    }

    var lastReached = -1;

    if (tripStatus == 'IN_PROGRESS') {
      for (var i = 0; i < n; i++) {
        final lat = (stops[i]['latitude'] as num?)?.toDouble();
        final lng = (stops[i]['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;

        final reached = gps.any(
          (p) => _distanceMeters(p.$1, p.$2, lat, lng) <= arrivalRadiusMeters,
        );
        if (reached) lastReached = i;
      }
    }

    return List.generate(n, (i) {
      if (i <= lastReached) return StopProgress.passed;
      if (i == lastReached + 1) return StopProgress.next;
      return StopProgress.upcoming;
    });
  }

  /// Khoảng cách giữa 2 toạ độ (mét) theo công thức haversine.
  static double _distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return 2 * earthRadius * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180;
}