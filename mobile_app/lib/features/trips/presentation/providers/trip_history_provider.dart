import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_app/features/trips/data/datasources/trip_history_remote_datasource.dart';
import 'package:mobile_app/features/trips/data/repositories/trip_history_repository_impl.dart';
import 'package:mobile_app/features/trips/domain/entities/trip_history_item.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_history_repository.dart';
import 'package:mobile_app/features/trips/domain/usecases/get_teacher_trip_history.dart';
import 'package:mobile_app/features/trips/presentation/providers/trip_provider.dart';

final tripHistoryRemoteDataSourceProvider =
    Provider<TripHistoryRemoteDataSource>(
  (ref) => TripHistoryRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final tripHistoryRepositoryProvider = Provider<TripHistoryRepository>(
  (ref) => TripHistoryRepositoryImpl(
    ref.watch(tripHistoryRemoteDataSourceProvider),
  ),
);

final getTeacherTripHistoryProvider = Provider<GetTeacherTripHistory>(
  (ref) => GetTeacherTripHistory(ref.watch(tripHistoryRepositoryProvider)),
);

/// Lịch sử đưa đón của giáo viên đang đăng nhập theo từng bộ lọc.
final tripHistoryProvider = FutureProvider.autoDispose
    .family<List<TripHistoryItem>, TripHistoryPeriod>((ref, period) async {
  // Ngày hiện tại theo giờ Việt Nam
  final vn = DateTime.now().toUtc().add(const Duration(hours: 7));
  final today = DateTime(vn.year, vn.month, vn.day);

  final (from, to) = period.range(today);

  final items = await ref
      .watch(getTeacherTripHistoryProvider)
      .call(from: from, to: to);

  if (period == TripHistoryPeriod.incident) {
    return items.where((item) => item.hasIncident).toList();
  }
  return items;
});