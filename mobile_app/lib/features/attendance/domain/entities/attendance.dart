enum AttendanceEventType {
  boarding,
  dropping,
}

class Attendance {
  final String id;
  final String tripId;
  final String studentId;
  final AttendanceEventType eventType;
  final DateTime eventTime;

  const Attendance({
    required this.id,
    required this.tripId,
    required this.studentId,
    required this.eventType,
    required this.eventTime,
  });
}