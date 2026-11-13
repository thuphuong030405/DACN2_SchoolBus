/// Tiến độ của xe đối với một điểm dừng.
enum StopProgress {
  passed, // đã qua
  next, // điểm tiếp theo
  upcoming, // chưa đến
}

class RouteStopInfo {
  final String stopId;
  final String name;
  final String address;
  final int order;
  final String? estimatedTime; // 'HH:mm' hoặc null
  final StopProgress progress;
  final double? latitude;
  final double? longitude;

  /// Số học sinh đón/trả tại điểm này (đếm theo student_id).
  final int studentCount;

  const RouteStopInfo({
    required this.stopId,
    required this.name,
    required this.address,
    required this.order,
    required this.estimatedTime,
    required this.progress,
    this.latitude,
    this.longitude,
    this.studentCount = 0,
  });

  bool get isCompleted => progress == StopProgress.passed;
  bool get isNext => progress == StopProgress.next;

  /// Điểm dừng đã có toạ độ để vẽ lên bản đồ.
  bool get hasLocation => latitude != null && longitude != null;
}

class TripRouteDetail {
  final String tripId;
  final String tripType; // MORNING | AFTERNOON
  final String status;
  final String routeCode;
  final String routeName;
  final String licensePlate;
  final DateTime startAt;
  final DateTime endAt;
  final List<RouteStopInfo> stops;

  /// Vị trí GPS mới nhất của xe (null nếu chưa có).
  final double? busLatitude;
  final double? busLongitude;

  const TripRouteDetail({
    required this.tripId,
    required this.tripType,
    required this.status,
    required this.routeCode,
    required this.routeName,
    required this.licensePlate,
    required this.startAt,
    required this.endAt,
    required this.stops,
    this.busLatitude,
    this.busLongitude,
  });

  bool get hasBusLocation => busLatitude != null && busLongitude != null;

  /// Tổng số học sinh trên cả tuyến.
  int get totalStudents => stops.fold(0, (sum, s) => sum + s.studentCount);

  String get title => tripType == 'MORNING'
      ? 'Đón học sinh buổi sáng'
      : 'Trả học sinh buổi chiều';

  String get timeRange => '${_hm(startAt)} - ${_hm(endAt)}';

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}