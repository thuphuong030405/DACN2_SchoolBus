import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_repository.dart';

class GetTeacherCurrentTripRoute {
  final TripRepository repository;

  const GetTeacherCurrentTripRoute(this.repository);

  Future<TripRouteDetail?> call(String authUserId) {
    return repository.getTeacherCurrentTripRoute(authUserId);
  }
}