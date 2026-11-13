/// Loại thông báo dùng để lọc + chọn icon/màu.
/// QUY ƯỚC: nơi TẠO thông báo phải ghi cột notification_type là một trong:
///   ATTENDANCE (lên/xuống xe), TRIP (xe sắp tới...), ALERT (cảnh báo), ABSENCE (đơn nghỉ), GENERAL
enum NotificationKind { attendance, trip, alert, absence, general }

class AppNotification {
  final String notificationId;
  final String title;
  final String message;
  final String notificationType;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedTripId;
  final String? relatedStudentId;

  AppNotification({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.notificationType,
    required this.isRead,
    required this.createdAt,
    this.relatedTripId,
    this.relatedStudentId,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      notificationId: json['notification_id'] as String,
      title: (json['title'] as String?) ?? '',
      message: (json['message'] as String?) ?? '',
      notificationType: (json['notification_type'] as String?) ?? 'GENERAL',
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      relatedTripId: json['related_trip_id'] as String?,
      relatedStudentId: json['related_student_id'] as String?,
    );
  }

  /// Phân loại theo cột notification_type (đúng nguồn dữ liệu).
  /// Chỉ khi dữ liệu cũ để GENERAL mới đoán theo tiêu đề (dự phòng).
  NotificationKind get kind {
    switch (notificationType.trim().toUpperCase()) {
      case 'ATTENDANCE':
        return NotificationKind.attendance;
      case 'TRIP':
        return NotificationKind.trip;
      case 'ALERT':
        return NotificationKind.alert;
      case 'ABSENCE':
        return NotificationKind.absence;
    }
    final t = title.toLowerCase();
    if (t.contains('lên xe') || t.contains('xuống xe') || t.contains('điểm danh')) {
      return NotificationKind.attendance;
    }
    if (t.contains('cảnh báo')) return NotificationKind.alert;
    if (t.contains('sắp tới')) return NotificationKind.trip;
    if (t.contains('nghỉ')) return NotificationKind.absence;
    return NotificationKind.general;
  }
}