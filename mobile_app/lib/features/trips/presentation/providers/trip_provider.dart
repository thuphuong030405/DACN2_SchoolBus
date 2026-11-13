import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/trips/data/datasources/trip_remote_datasource.dart';
import 'package:mobile_app/features/trips/data/repositories/trip_repository_impl.dart';
import 'package:mobile_app/features/trips/domain/entities/teacher_trip.dart';
import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';
import 'package:mobile_app/features/trips/domain/repositories/trip_repository.dart';
import 'package:mobile_app/features/trips/domain/usecases/get_teacher_current_trip_route.dart';
import 'package:mobile_app/features/trips/domain/usecases/get_teacher_today_trips.dart';

import 'package:mobile_app/core/offline/offline_store.dart';
import 'package:mobile_app/features/trips/data/models/teacher_trip_model.dart';

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

  final cacheKey = 'today_trips_${authUser.id}';
  try {
    
    await SyncService.flush();
    if (await SyncService.pendingNow() > 0) {
      throw Exception('Còn dữ liệu chờ đồng bộ');
    }
    
    final trips =
        await ref.watch(getTeacherTodayTripsProvider).call(authUser.id);

    List<TeacherTrip> result = trips;
    if (trips.isNotEmpty) {
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
      result = trips
          .map((t) => t.copyWith(
                totalStudents: total[t.tripId] ?? 0,
                attendedStudents: attended[t.tripId] ?? 0,
              ))
          .toList();
    }

    await OfflineStore.put(cacheKey, result.map(_tripToMap).toList());
    return result;
    } catch (e) {
    final cached = await OfflineStore.get(cacheKey);
    if (cached is List) {
      final now = DateTime.now();
      final trips = cached
          .map((e) => _tripFromMap(Map<String, dynamic>.from(e as Map)))
          .where((t) =>
              t.tripDate.year == now.year &&
              t.tripDate.month == now.month &&
              t.tripDate.day == now.day)
          .toList();
      return Future.wait(trips.map(_withLocalCounts)); // tính lại số đếm
    }
    rethrow;
  }
});

Map<String, dynamic> _tripToMap(TeacherTrip t) => {
      'trip_id': t.tripId,
      'trip_date': t.tripDate.toIso8601String(),
      'trip_type': t.tripType,
      'start_at': t.startAt.toIso8601String(),
      'end_at': t.endAt.toIso8601String(),
      'status': t.status,
      'route_code': t.routeCode,
      'route_name': t.routeName,
      'license_plate': t.licensePlate,
      'total': t.totalStudents,
      'attended': t.attendedStudents,
    };

TeacherTrip _tripFromMap(Map<String, dynamic> m) => TeacherTripModel(
      tripId: m['trip_id'] as String,
      tripDate: DateTime.parse(m['trip_date'] as String),
      tripType: m['trip_type'] as String,
      startAt: DateTime.parse(m['start_at'] as String),
      endAt: DateTime.parse(m['end_at'] as String),
      status: m['status'] as String,
      routeCode: m['route_code'] as String,
      routeName: m['route_name'] as String,
      licensePlate: m['license_plate'] as String,
      totalStudents: m['total'] as int,
      attendedStudents: m['attended'] as int,
    );
    /// Tính lại số học sinh/đã điểm danh từ danh sách điểm danh lưu trong máy.
Future<TeacherTrip> _withLocalCounts(TeacherTrip t) async {
  for (final name in ['list', 'face']) {
    final r = await OfflineStore.get('roster_${name}_${t.tripId}');
    if (r is List && r.isNotEmpty) {
      final attended = r
          .where((e) =>
              e is Map &&
              (e['status'] == 'BOARDED' || e['status'] == 'ALIGHTED'))
          .length;
      return t.copyWith(totalStudents: r.length, attendedStudents: attended);
    }
  }
  return t;
}

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