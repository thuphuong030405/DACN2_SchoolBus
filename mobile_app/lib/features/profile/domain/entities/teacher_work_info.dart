/// Thông tin công việc của giáo viên hiển thị ở trang hồ sơ.
class TeacherWorkInfo {
  /// Mã giáo viên (teachers.teacher_code).
  final String? teacherCode;

  /// Số chuyến đã hoàn thành.
  final int completedTrips;

  /// Số báo cáo sự cố do giáo viên đã gửi.
  final int reportedIncidents;

  /// Tỉ lệ chuyến đúng giờ từ 0 đến 1. Null khi chưa có chuyến nào hoàn thành.
  final double? onTimeRate;

  /// Xe và tuyến của chuyến hiện tại (hoặc chuyến gần nhất).
  final String? licensePlate;
  final String? routeName;

  /// Tài xế đi cùng ở chuyến đó.
  final String? driverName;

  /// Hạn bằng lái của tài xế (drivers.license_expiry).
  final DateTime? driverLicenseExpiry;

  const TeacherWorkInfo({
    this.teacherCode,
    this.completedTrips = 0,
    this.reportedIncidents = 0,
    this.onTimeRate,
    this.licensePlate,
    this.routeName,
    this.driverName,
    this.driverLicenseExpiry,
  });
}