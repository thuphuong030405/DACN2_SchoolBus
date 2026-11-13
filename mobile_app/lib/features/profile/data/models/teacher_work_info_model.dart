import 'package:mobile_app/features/profile/domain/entities/teacher_work_info.dart';

class TeacherWorkInfoModel extends TeacherWorkInfo {
  const TeacherWorkInfoModel({
    super.teacherCode,
    super.completedTrips,
    super.reportedIncidents,
    super.onTimeRate,
    super.licensePlate,
    super.routeName,
    super.driverName,
    super.driverLicenseExpiry,
  });

  /// Ghép kết quả của nhiều truy vấn thành một đối tượng.
  /// [currentTrip] là 1 dòng trips kèm buses(...), routes(...),
  /// drivers(license_expiry, users(full_name)).
  factory TeacherWorkInfoModel.fromParts({
    required String? teacherCode,
    required int completedTrips,
    required int reportedIncidents,
    required int delayedTrips,
    required Map<String, dynamic>? currentTrip,
  }) {
    // Đúng giờ = chuyến hoàn thành mà không có cảnh báo TRIP_DELAY
    final onTimeRate = completedTrips == 0
        ? null
        : ((completedTrips - delayedTrips) / completedTrips)
            .clamp(0.0, 1.0)
            .toDouble();

    final bus = currentTrip?['buses'] as Map<String, dynamic>?;
    final route = currentTrip?['routes'] as Map<String, dynamic>?;
    final driver = currentTrip?['drivers'] as Map<String, dynamic>?;
    final driverUser = driver?['users'] as Map<String, dynamic>?;

    final licenseRaw = driver?['license_expiry'] as String?;

    return TeacherWorkInfoModel(
      teacherCode: teacherCode,
      completedTrips: completedTrips,
      reportedIncidents: reportedIncidents,
      onTimeRate: onTimeRate,
      licensePlate: bus?['license_plate'] as String?,
      routeName: route?['route_name'] as String?,
      driverName: driverUser?['full_name'] as String?,
      driverLicenseExpiry:
          licenseRaw == null ? null : DateTime.tryParse(licenseRaw),
    );
  }
}