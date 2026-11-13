DateTime? dtParser(dynamic v) => v == null ? null : DateTime.parse(v as String).toLocal();

class ChildDetail {
  const ChildDetail({
    required this.studentId,
    required this.studentCode,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.className,
    required this.avatarUrl,
  });

  final String studentId;
  final String studentCode;
  final String fullName;
  final DateTime dateOfBirth;
  final String? gender;
  final String? className;
  final String? avatarUrl;

  factory ChildDetail.fromMap(Map<String, dynamic> m) => ChildDetail(
        studentId: m['student_id'] as String,
        studentCode: m['student_code'] as String,
        fullName: m['full_name'] as String,
        dateOfBirth: DateTime.parse(m['date_of_birth'] as String),
        gender: m['gender'] as String?,
        className: m['class_name'] as String?,
        avatarUrl: m['avatar_url'] as String?,
      );

  String get genderLabel => switch (gender) {
        'MALE' => 'Nam',
        'FEMALE' => 'Nữ',
        'OTHER' => 'Khác',
        _ => '—',
      };
}

class FaceStatus {
  const FaceStatus({
    required this.consentStatus,
    this.consentedAt,
    required this.hasFace,
    required this.sampleCount,
    this.modelName,
    this.enrolledAt,
    this.enrolledBy,
  });

  final String consentStatus;
  final DateTime? consentedAt;
  final bool hasFace;
  final int sampleCount;
  final String? modelName;
  final DateTime? enrolledAt;
  final String? enrolledBy;

  bool get isGranted => consentStatus == 'GRANTED';

  factory FaceStatus.fromMap(Map<String, dynamic>? m) => m == null
      ? const FaceStatus(consentStatus: 'PENDING', hasFace: false, sampleCount: 0)
      : FaceStatus(
          consentStatus: (m['consent_status'] as String?) ?? 'PENDING',
          consentedAt: dtParser(m['consented_at']),
          hasFace: (m['has_face'] as bool?) ?? false,
          sampleCount: (m['sample_count'] as num?)?.toInt() ?? 0,
          modelName: m['model_name'] as String?,
          enrolledAt: dtParser(m['enrolled_at']),
          enrolledBy: m['enrolled_by'] as String?,
        );
}