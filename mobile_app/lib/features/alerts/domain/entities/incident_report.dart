/// Loại sự cố (khớp cột alerts.incident_type).
enum IncidentType {
  breakdown('BREAKDOWN', 'Xe hỏng'),
  traffic('TRAFFIC', 'Kẹt xe, trễ'),
  accident('ACCIDENT', 'Va chạm'),
  studentSick('STUDENT_SICK', 'Học sinh ốm'),
  lostItem('LOST_ITEM', 'Đồ thất lạc'),
  other('OTHER', 'Khác');

  const IncidentType(this.code, this.label);

  final String code;
  final String label;
}

/// Mức độ (khớp CHECK alerts.severity: LOW, MEDIUM, HIGH, CRITICAL).
enum IncidentSeverity {
  low('LOW', 'Thấp'),
  medium('MEDIUM', 'Trung bình'),
  high('HIGH', 'Cao'),
  urgent('CRITICAL', 'Khẩn cấp');

  const IncidentSeverity(this.code, this.label);

  final String code;
  final String label;
}

/// Báo cáo sự cố do giáo viên gửi từ màn "Báo cáo sự cố".
class IncidentReport {
  /// Tối đa số ảnh đính kèm.
  static const int maxPhotos = 4;

  final String tripId;
  final IncidentType type;
  final IncidentSeverity severity;
  final String description;
  final bool notifyParents;

  /// Đường dẫn ảnh trên máy, sẽ được tải lên Storage khi gửi.
  final List<String> localPhotoPaths;

  const IncidentReport({
    required this.tripId,
    required this.type,
    required this.severity,
    required this.description,
    required this.notifyParents,
    this.localPhotoPaths = const [],
  });
}

/// Lỗi nghiệp vụ hiển thị được cho người dùng.
class IncidentException implements Exception {
  final String message;

  const IncidentException(this.message);

  @override
  String toString() => message;
}