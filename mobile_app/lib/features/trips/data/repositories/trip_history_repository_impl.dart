import 'package:mobile_app/features/trips/data/datasources/trip_history_remote_datasource.dart';
import 'package:mobile_app/features/trips/domain/entities/trip_history_item.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_history_repository.dart';

class TripHistoryRepositoryImpl implements TripHistoryRepository {
  final TripHistoryRemoteDataSource remote;

  const TripHistoryRepositoryImpl(this.remote);

  @override
  Future<List<TripHistoryItem>> getTeacherTripHistory({
    required DateTime from,
    required DateTime to,
  }) {
    return remote.getTeacherTripHistory(from: from, to: to);
  }
}