import 'package:mobile_app/features/trips/domain/entities/teacher_trip.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_repository.dart';

class GetTeacherTodayTrips {
  final TripRepository repository;

  const GetTeacherTodayTrips(this.repository);

  Future<List<TeacherTrip>> call(String authUserId) {
    return repository.getTeacherTodayTrips(authUserId);
  }
}