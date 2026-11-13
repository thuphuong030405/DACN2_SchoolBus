import 'package:mobile_app/features/trips/domain/entities/trip_history_item.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_history_repository.dart';

class GetTeacherTripHistory {
  final TripHistoryRepository repository;

  const GetTeacherTripHistory(this.repository);

  Future<List<TripHistoryItem>> call({
    required DateTime from,
    required DateTime to,
  }) {
    return repository.getTeacherTripHistory(from: from, to: to);
  }
}