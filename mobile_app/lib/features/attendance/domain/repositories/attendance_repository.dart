import '../entities/attendance.dart';

abstract class AttendanceRepository {
  Future<void> recordAttendance(Attendance attendance);

  Future<List<Attendance>> getAttendanceByTrip(
    String tripId,
  );
}