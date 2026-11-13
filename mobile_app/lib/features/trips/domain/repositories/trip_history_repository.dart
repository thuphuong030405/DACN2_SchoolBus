import 'package:mobile_app/features/trips/domain/entities/trip_history_item.dart';

abstract class TripHistoryRepository {
  /// Các chuyến đã kết thúc (hoàn tất hoặc huỷ) của giáo viên đang đăng nhập
  /// trong khoảng ngày [from] đến [to], mới nhất trước.
  Future<List<TripHistoryItem>> getTeacherTripHistory({
    required DateTime from,
    required DateTime to,
  });
}