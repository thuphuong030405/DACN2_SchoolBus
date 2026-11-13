import 'dart:math' as math;

/// Khoảng cách giữa 2 toạ độ (mét) theo công thức haversine.
double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
  const earthRadius = 6371000.0;
  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_rad(lat1)) *
          math.cos(_rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  return 2 * earthRadius * math.asin(math.sqrt(a));
}

/// Tổng độ dài (km) của đường nối lần lượt các điểm (đường chim bay).
/// Trả về null nếu có ít hơn 2 điểm.
double? routeDistanceKm(List<(double, double)> points) {
  if (points.length < 2) return null;

  var meters = 0.0;
  for (var i = 0; i < points.length - 1; i++) {
    meters += distanceMeters(
      points[i].$1,
      points[i].$2,
      points[i + 1].$1,
      points[i + 1].$2,
    );
  }
  return meters / 1000;
}

double _rad(double deg) => deg * math.pi / 180;