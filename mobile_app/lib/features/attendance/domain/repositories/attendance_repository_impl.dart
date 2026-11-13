import '../../domain/entities/attendance.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final List<Attendance> _records = [];

  @override
  Future<void> recordAttendance(Attendance attendance) async {
    _records.add(attendance);
  }

  @override
  Future<List<Attendance>> getAttendanceByTrip(
    String tripId,
  ) async {
    return _records
        .where((item) => item.tripId == tripId)
        .toList();
  }
}