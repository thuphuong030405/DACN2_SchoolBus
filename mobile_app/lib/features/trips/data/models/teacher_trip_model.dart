import 'package:mobile_app/features/trips/domain/entities/teacher_trip.dart';

class TeacherTripModel extends TeacherTrip {
  const TeacherTripModel({
    required super.tripId,
    required super.tripDate,
    required super.tripType,
    required super.startAt,
    required super.endAt,
    required super.status,
    required super.routeCode,
    required super.routeName,
    required super.licensePlate,
    required super.totalStudents,
    required super.attendedStudents,
  });

  /// [json] là 1 dòng của bảng trips kèm routes(...) và buses(...).
  factory TeacherTripModel.fromJson(
    Map<String, dynamic> json, {
    required int totalStudents,
    required int attendedStudents,
  }) {
    final route = json['routes'] as Map<String, dynamic>? ?? const {};
    final bus = json['buses'] as Map<String, dynamic>? ?? const {};

    return TeacherTripModel(
      tripId: json['trip_id'] as String,
      tripDate: DateTime.parse(json['trip_date'] as String),
      tripType: json['trip_type'] as String,
      startAt: DateTime.parse(json['start_at'] as String).toLocal(),
      endAt: DateTime.parse(json['end_at'] as String).toLocal(),
      status: json['status'] as String,
      routeCode: route['route_code'] as String? ?? '',
      routeName: route['route_name'] as String? ?? '',
      licensePlate: bus['license_plate'] as String? ?? '',
      totalStudents: totalStudents,
      attendedStudents: attendedStudents,
    );
  }
}