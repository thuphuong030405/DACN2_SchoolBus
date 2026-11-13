/// Bộ lọc thời gian của màn hình lịch sử đưa đón.
enum TripHistoryPeriod {
  week('Tuần này'),
  month('Tháng này'),
  incident('Có sự cố');

  final String label;

  const TripHistoryPeriod(this.label);

  /// Khoảng ngày cần lấy dữ liệu. [today] là ngày hiện tại (giờ Việt Nam).
  (DateTime, DateTime) range(DateTime today) {
    switch (this) {
      case TripHistoryPeriod.week:
        // Từ thứ Hai đến Chủ nhật của tuần hiện tại
        final monday = DateTime(
          today.year,
          today.month,
          today.day - (today.weekday - 1),
        );
        return (monday, DateTime(monday.year, monday.month, monday.day + 6));

      case TripHistoryPeriod.month:
        return (
          DateTime(today.year, today.month, 1),
          DateTime(today.year, today.month + 1, 0),
        );

      case TripHistoryPeriod.incident:
        // Tìm các chuyến có sự cố trong 90 ngày gần nhất
        return (
          DateTime(today.year, today.month, today.day - 89),
          DateTime(today.year, today.month, today.day),
        );
    }
  }
}

/// Một chuyến xe đã kết thúc trong lịch sử của giáo viên.
class TripHistoryItem {
  final String tripId;

  /// Ngày của chuyến (chỉ có ý nghĩa phần ngày/tháng/năm).
  final DateTime tripDate;

  final String tripType; // MORNING | AFTERNOON

  /// Giờ bắt đầu / kết thúc theo lịch của chuyến, đã đổi sang giờ Việt Nam.
  final DateTime startAt;
  final DateTime endAt;

  final String status; // COMPLETED | CANCELLED
  final String routeName;
  final String licensePlate;

  /// Tổng số học sinh trong danh sách điểm danh của chuyến.
  final int totalStudents;

  /// Số học sinh đã lên xe (BOARDED hoặc ALIGHTED).
  final int boardedStudents;

  /// Chuyến có cảnh báo trễ giờ (TRIP_DELAY).
  final bool isDelayed;

  /// Chuyến có cảnh báo/sự cố khác ngoài trễ giờ.
  final bool hasIncident;

  const TripHistoryItem({
    required this.tripId,
    required this.tripDate,
    required this.tripType,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.routeName,
    required this.licensePlate,
    required this.totalStudents,
    required this.boardedStudents,
    required this.isDelayed,
    required this.hasIncident,
  });

  bool get isMorning => tripType == 'MORNING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED';

  String get title => isMorning ? 'Đón sáng' : 'Trả chiều';

  String get timeRange => '${_hm(startAt)} – ${_hm(endAt)}';

  /// Ví dụ "29/31". Rỗng nếu chuyến không có danh sách điểm danh.
  String get attendanceText =>
      totalStudents == 0 ? '' : '$boardedStudents/$totalStudents';

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}