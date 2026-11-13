class TeacherTrip {
  final String tripId;
  final DateTime tripDate;
  final String tripType; // MORNING | AFTERNOON
  final DateTime startAt;
  final DateTime endAt;
  final String status; // SCHEDULED | IN_PROGRESS | COMPLETED | CANCELLED
  final String routeCode;
  final String routeName;
  final String licensePlate;
  final int totalStudents;
  final int attendedStudents;

  const TeacherTrip({
    required this.tripId,
    required this.tripDate,
    required this.tripType,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.routeCode,
    required this.routeName,
    required this.licensePlate,
    required this.totalStudents,
    required this.attendedStudents,
  });

  TeacherTrip copyWith({
    int? totalStudents,
    int? attendedStudents,
  }) {
    return TeacherTrip(
      tripId: tripId,
      tripDate: tripDate,
      tripType: tripType,
      startAt: startAt,
      endAt: endAt,
      status: status,
      routeCode: routeCode,
      routeName: routeName,
      licensePlate: licensePlate,
      totalStudents: totalStudents ?? this.totalStudents,
      attendedStudents: attendedStudents ?? this.attendedStudents,
    );
  }

  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isScheduled => status == 'SCHEDULED';

  int get remainingStudents =>
      (totalStudents - attendedStudents).clamp(0, totalStudents);

  double get progress =>
      totalStudents == 0 ? 0 : (attendedStudents / totalStudents).clamp(0, 1);

  String get title =>
      tripType == 'MORNING' ? 'Đón sáng' : 'Trả chiều';

  String get timeRange => '${_hm(startAt)} - ${_hm(endAt)}';

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}