import 'package:mobile_app/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:mobile_app/features/trips/domain/entities/teacher_trip.dart';
import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource remote;

  const TripRepositoryImpl(this.remote);

  @override
  Future<List<TeacherTrip>> getTeacherTodayTrips(String authUserId) {
    return remote.getTeacherTodayTrips(authUserId);
  }

  @override
  Future<TripRouteDetail?> getTeacherCurrentTripRoute(String authUserId) {
    return remote.getTeacherCurrentTripRoute(authUserId);
  }
}