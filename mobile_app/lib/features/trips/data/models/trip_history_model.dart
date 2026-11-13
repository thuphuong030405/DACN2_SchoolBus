import 'package:mobile_app/features/trips/domain/entities/trip_history_item.dart';

class TripHistoryModel extends TripHistoryItem {
  const TripHistoryModel({
    required super.tripId,
    required super.tripDate,
    required super.tripType,
    required super.startAt,
    required super.endAt,
    required super.status,
    required super.routeName,
    required super.licensePlate,
    required super.totalStudents,
    required super.boardedStudents,
    required super.isDelayed,
    required super.hasIncident,
  });

  /// [json] là 1 dòng do hàm get_teacher_trip_history trả về.
  factory TripHistoryModel.fromJson(Map<String, dynamic> json) {
    return TripHistoryModel(
      tripId: json['trip_id'] as String,
      tripDate: _parseDate(json['trip_date'] as String),
      tripType: json['trip_type'] as String,
      startAt: _toVietnamTime(json['start_at'] as String),
      endAt: _toVietnamTime(json['end_at'] as String),
      status: json['status'] as String,
      routeName: json['route_name'] as String? ?? '',
      licensePlate: json['license_plate'] as String? ?? '',
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      boardedStudents: (json['boarded_students'] as num?)?.toInt() ?? 0,
      isDelayed: json['is_delayed'] as bool? ?? false,
      hasIncident: json['has_incident'] as bool? ?? false,
    );
  }

  /// 'yyyy-MM-dd' -> DateTime(y, m, d)
  static DateTime _parseDate(String value) {
    final p = value.split('-');
    return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
  }

  /// Đổi thời điểm UTC sang giờ Việt Nam (UTC+7) để hiển thị đúng
  /// dù điện thoại đang đặt múi giờ nào.
  static DateTime _toVietnamTime(String iso) {
    return DateTime.parse(iso).toUtc().add(const Duration(hours: 7));
  }
}