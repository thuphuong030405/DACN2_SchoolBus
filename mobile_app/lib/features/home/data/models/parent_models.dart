class ChildInfo {
  final String studentId;
  final String? studentCode;
  final String fullName;
  final String? className;
  final String? avatarUrl;
  final String relationship;
  final String verificationStatus; // PENDING / APPROVED / REJECTED
  final bool notificationsEnabled; // Khắc phục lỗi thiếu getter notificationsEnabled

  const ChildInfo({
    required this.studentId,
    required this.studentCode,
    required this.fullName,
    required this.className,
    required this.avatarUrl,
    required this.relationship,
    required this.verificationStatus,
    this.notificationsEnabled = true,
  });

  bool get isApproved => verificationStatus == 'APPROVED';

  factory ChildInfo.fromMap(Map<String, dynamic> m) {
    final s = m['students'] as Map<String, dynamic>?;
    return ChildInfo(
      studentId: m['student_id'] as String,
      studentCode: s?['student_code'] as String?,
      fullName: (s?['full_name'] as String?) ?? 'Đang chờ nhà trường duyệt',
      className: s?['class_name'] as String?,
      avatarUrl: s?['avatar_url'] as String?,
      relationship: m['relationship'] as String,
      verificationStatus: m['verification_status'] as String,
      notificationsEnabled: m['notifications_enabled'] ?? true,
    );
  }
}

// Khắc phục lỗi thiếu ChildProfileInfo
class ChildProfileInfo {
  final String studentId;
  final String fullName;
  final String? className;
  final String? avatarUrl;
  final String? studentCode;
  
  // Các trường bổ sung theo lỗi biên dịch
  final String? routeName;
  final String? pickupAddress;
  final String? pickupStopName;
  final String? dropoffStopName;

  const ChildProfileInfo({
    required this.studentId,
    required this.fullName,
    this.className,
    this.avatarUrl,
    this.studentCode,
    this.routeName,
    this.pickupAddress,
    this.pickupStopName,
    this.dropoffStopName,
  });

  factory ChildProfileInfo.fromMap(Map<String, dynamic> map) {
    return ChildProfileInfo(
      studentId: map['student_id'] ?? '',
      fullName: map['full_name'] ?? '',
      className: map['class_name'],
      avatarUrl: map['avatar_url'],
      studentCode: map['student_code'],
      routeName: map['route_name'],
      pickupAddress: map['pickup_address'],
      pickupStopName: map['pickup_stop_name'],
      dropoffStopName: map['dropoff_stop_name'],
    );
  }
}

// Khắc phục lỗi thiếu FaceStage enum
enum FaceStage {
  ready,
  waitingSchool,
  revoked,
  notConsented,
}

class TodayTrip {
  final String tripId;
  final String tripType; // MORNING / AFTERNOON
  final String tripStatus; // SCHEDULED / IN_PROGRESS / COMPLETED
  final DateTime startAt;
  final DateTime endAt;
  final String busCode;
  final String licensePlate;
  final String driverName;
  final String? driverPhone;
  final String teacherName;
  final String? teacherPhone;
  final String pickupStopName;
  final String dropoffStopName;
  final String attendanceStatus; // PENDING / BOARDED / ALIGHTED / ABSENT
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  final String? routeCode;
  final String? routeName;
  final String? pickupEstimatedTime;
  final String? dropoffEstimatedTime;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;

  const TodayTrip({
    required this.tripId,
    required this.tripType,
    required this.tripStatus,
    required this.startAt,
    required this.endAt,
    required this.busCode,
    required this.licensePlate,
    required this.driverName,
    required this.driverPhone,
    required this.teacherName,
    required this.teacherPhone,
    required this.pickupStopName,
    required this.dropoffStopName,
    required this.attendanceStatus,
    required this.checkInTime,
    required this.checkOutTime,
    this.routeCode,
    this.routeName,
    this.pickupEstimatedTime,
    this.dropoffEstimatedTime,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
  });

  factory TodayTrip.fromMap(Map<String, dynamic> m) {
    DateTime? t(String k) =>
        m[k] == null ? null : DateTime.parse(m[k] as String).toLocal();
    double? d(String k) => (m[k] as num?)?.toDouble();
    return TodayTrip(
      tripId: m['trip_id'] as String,
      tripType: m['trip_type'] as String,
      tripStatus: m['trip_status'] as String,
      startAt: t('start_at')!,
      endAt: t('end_at')!,
      busCode: m['bus_code'] as String,
      licensePlate: m['license_plate'] as String,
      driverName: m['driver_name'] as String,
      driverPhone: m['driver_phone'] as String?,
      teacherName: m['teacher_name'] as String,
      teacherPhone: m['teacher_phone'] as String?,
      pickupStopName: m['pickup_stop_name'] as String,
      dropoffStopName: m['dropoff_stop_name'] as String,
      attendanceStatus: m['attendance_status'] as String,
      checkInTime: t('check_in_time'),
      checkOutTime: t('check_out_time'),
      routeCode: m['route_code'] as String?,
      routeName: m['route_name'] as String?,
      pickupEstimatedTime: m['pickup_estimated_time'] as String?,
      dropoffEstimatedTime: m['dropoff_estimated_time'] as String?,
      pickupLat: d('pickup_lat'),
      pickupLng: d('pickup_lng'),
      dropoffLat: d('dropoff_lat'),
      dropoffLng: d('dropoff_lng'),
    );
  }

  String get tripTypeLabel => tripType == 'MORNING' ? 'Chuyến sáng' : 'Chuyến chiều';
  bool get isActive => tripStatus == 'IN_PROGRESS';
}

class GpsPoint {
  final double lat;
  final double lng;
  final double? speed;
  final DateTime recordedAt;

  const GpsPoint({
    required this.lat,
    required this.lng,
    required this.speed,
    required this.recordedAt,
  });

  factory GpsPoint.fromMap(Map<String, dynamic> m) => GpsPoint(
        lat: (m['latitude'] as num).toDouble(),
        lng: (m['longitude'] as num).toDouble(),
        speed: (m['speed'] as num?)?.toDouble(),
        recordedAt: DateTime.parse(m['recorded_at'] as String).toLocal(),
      );
}

class ParentProfile {
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? address;
  final String? occupation;

  const ParentProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.address,
    this.occupation,
  });

  factory ParentProfile.fromMap(Map<String, dynamic> m) {
    final p = m['parents'];
    final Map<String, dynamic>? pm = p is List
        ? (p.isEmpty ? null : p.first as Map<String, dynamic>)
        : p as Map<String, dynamic>?;
    return ParentProfile(
      userId: m['user_id'] as String,
      fullName: m['full_name'] as String,
      email: m['email'] as String,
      phone: m['phone'] as String?,
      avatarUrl: m['avatar_url'] as String?,
      address: pm?['address'] as String?,
      occupation: pm?['occupation'] as String?,
    );
  }
}

class FaceConsent {
  final String status; // PENDING / GRANTED / REVOKED
  final DateTime? consentedAt;
  final String? version;

  const FaceConsent({required this.status, this.consentedAt, this.version});

  bool get isGranted => status == 'GRANTED';

  factory FaceConsent.fromMap(Map<String, dynamic>? m) => m == null
      ? const FaceConsent(status: 'PENDING')
      : FaceConsent(
          status: m['consent_status'] as String,
          consentedAt: m['consented_at'] == null
              ? null
              : DateTime.parse(m['consented_at'] as String).toLocal(),
          version: m['consent_version'] as String?,
        );
}