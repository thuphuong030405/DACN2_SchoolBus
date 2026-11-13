import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:mobile_app/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:mobile_app/features/trips/domain/entities/teacher_trip.dart';
import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_repository.dart';
import 'package:mobile_app/features/trips/domain/usecases/get_teacher_current_trip_route.dart';
import 'package:mobile_app/features/trips/domain/usecases/get_teacher_today_trips.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>(
  (ref) => TripRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepositoryImpl(ref.watch(tripRemoteDataSourceProvider)),
);

final getTeacherTodayTripsProvider = Provider<GetTeacherTodayTrips>(
  (ref) => GetTeacherTodayTrips(ref.watch(tripRepositoryProvider)),
);

/// Danh sách chuyến xe hôm nay của giáo viên đang đăng nhập.
final teacherTodayTripsProvider =
    FutureProvider.autoDispose<List<TeacherTrip>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authUser = client.auth.currentUser;

  if (authUser == null) {
    throw Exception('Chưa đăng nhập');
  }

  final trips =
      await ref.watch(getTeacherTodayTripsProvider).call(authUser.id);
  if (trips.isEmpty) return trips;

  final rows = await client
      .from('attendance')
      .select('trip_id, status')
      .inFilter('trip_id', trips.map((t) => t.tripId).toList());

  final total = <String, int>{};
  final attended = <String, int>{};

  for (final r in rows) {
    final id = r['trip_id'] as String;
    total[id] = (total[id] ?? 0) + 1;

    final status = r['status'];
    if (status == 'BOARDED' || status == 'ALIGHTED') {
      attended[id] = (attended[id] ?? 0) + 1;
    }
  }

  return trips
      .map((t) => t.copyWith(
            totalStudents: total[t.tripId] ?? 0,
            attendedStudents: attended[t.tripId] ?? 0,
          ))
      .toList();
});

final getTeacherCurrentTripRouteProvider =
    Provider<GetTeacherCurrentTripRoute>(
  (ref) => GetTeacherCurrentTripRoute(ref.watch(tripRepositoryProvider)),
);

/// Lộ trình (điểm dừng) của chuyến hiện tại của giáo viên đang đăng nhập.
final teacherRouteDetailProvider =
    FutureProvider.autoDispose<TripRouteDetail?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authUser = client.auth.currentUser;

  if (authUser == null) {
    throw Exception('Chưa đăng nhập');
  }

  return ref.watch(getTeacherCurrentTripRouteProvider).call(authUser.id);
});