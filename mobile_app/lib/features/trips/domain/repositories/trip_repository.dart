import 'package:mobile_app/features/trips/domain/entities/teacher_trip.dart';
import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';

abstract class TripRepository {
  /// Các chuyến xe trong ngày hôm nay của giáo viên đang đăng nhập.
  Future<List<TeacherTrip>> getTeacherTodayTrips(String authUserId);

  /// Chuyến hiện tại (hoặc chuyến gần nhất trong ngày) kèm các điểm dừng.
  Future<TripRouteDetail?> getTeacherCurrentTripRoute(String authUserId);
}