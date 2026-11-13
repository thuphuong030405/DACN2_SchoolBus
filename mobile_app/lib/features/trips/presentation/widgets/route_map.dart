import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';
import 'package:mobile_app/features/trips/presentation/widgets/route_palette.dart';

/// Bản đồ OpenStreetMap hiển thị các điểm đón/dừng của tuyến (giao diện theo Figma).
/// - Tick xanh: đã qua (đường nối liền)
/// - Chấm đỏ + nhãn tên: điểm tiếp theo (đường nối chấm nét)
/// - Chấm navy: điểm đến cuối tuyến
/// - Vòng trắng viền xanh: điểm chưa đến
/// - Xe buýt vàng có vòng sáng: vị trí xe
class RouteMap extends StatelessWidget {
  final List<RouteStopInfo> stops;
  final MapController controller;
  final String? selectedStopId;
  final ValueChanged<RouteStopInfo> onStopTap;
  final double height;
  final bool showLegend;
  final BorderRadius borderRadius;

  /// Vị trí GPS mới nhất của xe. Null thì không vẽ xe.
  final LatLng? busPosition;

  /// Khoảng cách từ đỉnh bản đồ tới thẻ thông tin điểm đang chọn.
  final double infoTopOffset;

  /// Khoảng cách từ đỉnh bản đồ tới nút "xem toàn tuyến".
  final double controlsTopOffset;

  /// Chừa chỗ phía dưới để dòng ghi nguồn bản đồ không bị che.
  final double attributionBottomInset;

  const RouteMap({
    super.key,
    required this.stops,
    required this.controller,
    required this.onStopTap,
    this.selectedStopId,
    this.busPosition,
    this.height = 280,
    this.showLegend = true,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.infoTopOffset = 8,
    this.controlsTopOffset = 8,
    this.attributionBottomInset = 0,
  });

  LatLng _point(RouteStopInfo s) => LatLng(s.latitude!, s.longitude!);

  void _fitAll(List<LatLng> points) {
    if (points.length == 1) {
      controller.move(points.first, 15);
    } else {
      controller.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.all(48),
          maxZoom: 16,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final located = stops.where((s) => s.hasLocation).toList();

    if (located.isEmpty) return _buildEmpty();

    final points = located.map(_point).toList();
    final selected =
        located.where((s) => s.stopId == selectedStopId).firstOrNull;

    final mapKey = ValueKey(
      located.map((s) => '${s.stopId}${s.latitude}${s.longitude}').join('|'),
    );

    // Đường đã đi (liền) và đường còn lại (chấm nét).
    final lastPassed = located.lastIndexWhere((s) => s.isCompleted);
    final solidPoints =
        lastPassed >= 1 ? points.sublist(0, lastPassed + 1) : <LatLng>[];
    final dottedPoints =
        lastPassed >= 0 ? points.sublist(lastPassed) : points;

    final map = ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              key: mapKey,
              mapController: controller,
              options: MapOptions(
                initialCenter: points.first,
                initialZoom: 15,
                initialCameraFit: points.length > 1
                    ? CameraFit.coordinates(
                        coordinates: points,
                        padding: const EdgeInsets.all(48),
                        maxZoom: 16,
                      )
                    : null,
                minZoom: 3,
                maxZoom: 19,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // TODO: đổi thành applicationId của app (android/app/build.gradle)
                  userAgentPackageName: 'com.example.mobile_app',
                ),
                PolylineLayer(
                  polylines: [
                    if (dottedPoints.length > 1)
                      Polyline(
                        points: dottedPoints,
                        strokeWidth: 4,
                        color: RoutePalette.blue,
                        // flutter_map v8. Nếu dùng v7: bỏ dòng này, thêm isDotted: true
                        pattern: StrokePattern.dotted(),
                        strokeCap: StrokeCap.round,
                      ),
                    if (solidPoints.length > 1)
                      Polyline(
                        points: solidPoints,
                        strokeWidth: 4,
                        color: RoutePalette.blue,
                        strokeCap: StrokeCap.round,
                      ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (var i = 0; i < located.length; i++)
                      Marker(
                        point: _point(located[i]),
                        width: 190,
                        height: 44,
                        child: _buildMarker(
                          stop: located[i],
                          number: stops.indexOf(located[i]) + 1,
                          isLast: stops.indexOf(located[i]) == stops.length - 1,
                          isSelected: located[i].stopId == selectedStopId,
                        ),
                      ),
                  ],
                ),
                if (busPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: busPosition!,
                        width: 64,
                        height: 64,
                        child: const IgnorePointer(child: _BusMarker()),
                      ),
                    ],
                  ),
                Padding(
                  padding: EdgeInsets.only(bottom: attributionBottomInset),
                  child: const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ),
              ],
            ),

            // Thông tin điểm đang chọn
            if (selected != null)
              Positioned(
                top: infoTopOffset,
                left: 16,
                right: 72,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2310224A),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selected.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RoutePalette.text(
                                13,
                                FontWeight.w700,
                                RoutePalette.navy,
                              ),
                            ),
                            Text(
                              selected.studentCount > 0
                                  ? '${selected.address} · ${selected.studentCount} học sinh'
                                  : selected.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: RoutePalette.text(
                                11,
                                FontWeight.w400,
                                RoutePalette.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected.estimatedTime != null)
                        Text(
                          selected.estimatedTime!,
                          style: RoutePalette.text(
                            12,
                            FontWeight.w600,
                            RoutePalette.blueDark,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // Nút xem toàn tuyến
            Positioned(
              top: controlsTopOffset,
              right: 16,
              child: Material(
                color: Colors.white,
                elevation: 2,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Xem toàn tuyến',
                  icon: const Icon(
                    Icons.fit_screen,
                    color: RoutePalette.blue,
                    size: 22,
                  ),
                  onPressed: () => _fitAll(points),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!showLegend) return map;

    return Column(
      children: [
        map,
        const SizedBox(height: 10),
        _buildLegend(),
      ],
    );
  }

  Widget _buildMarker({
    required RouteStopInfo stop,
    required int number,
    required bool isLast,
    required bool isSelected,
  }) {
    final showLabel = stop.isNext || isSelected;

    final Widget dot;
    if (stop.isCompleted) {
      dot = _dot(
        RoutePalette.blue,
        size: isSelected ? 30 : 26,
        child: const Icon(Icons.check, size: 15, color: Colors.white),
      );
    } else if (isLast) {
      dot = _dot(RoutePalette.navy, size: isSelected ? 26 : 22);
    } else if (stop.isNext) {
      dot = _dot(RoutePalette.red, size: isSelected ? 26 : 22);
    } else {
      dot = _dot(
        Colors.white,
        size: isSelected ? 28 : 24,
        borderColor: RoutePalette.blue,
        child: Text(
          '$number',
          style: RoutePalette.text(11, FontWeight.w700, RoutePalette.grey),
        ),
      );
    }

    final label = stop.studentCount > 0
        ? '${stop.name} · ${stop.studentCount} HS'
        : stop.name;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onStopTap(stop),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          dot,
          if (showLabel)
            Positioned(
              left: 95 + 18, // 1/2 chiều rộng marker + nửa chấm + khoảng cách
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 76),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2210224A),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RoutePalette.text(
                      11,
                      FontWeight.w700,
                      RoutePalette.navy,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(
    Color color, {
    required double size,
    Widget? child,
    Color? borderColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: borderColor ?? Colors.white,
          width: borderColor != null ? 2.5 : 2.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3310224A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildLegend() {
    Widget item(Color fill, Color border, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: RoutePalette.text(12, FontWeight.w400, RoutePalette.navy),
            ),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(RoutePalette.blue, RoutePalette.blue, 'Đã qua'),
        item(RoutePalette.red, RoutePalette.red, 'Điểm tiếp theo'),
        item(Colors.white, RoutePalette.blue, 'Chưa đến'),
        item(RoutePalette.navy, RoutePalette.navy, 'Điểm đến'),
      ],
    );
  }

  Widget _buildEmpty() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: RoutePalette.blueLight,
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 48, color: RoutePalette.blue),
          const SizedBox(height: 10),
          Text(
            'Chưa có bản đồ',
            style: RoutePalette.text(14, FontWeight.w700, RoutePalette.navy),
          ),
          const SizedBox(height: 4),
          Text(
            'Các điểm dừng của tuyến chưa có toạ độ.',
            style: RoutePalette.text(12, FontWeight.w400, RoutePalette.grey),
          ),
        ],
      ),
    );
  }
}

/// Xe buýt vàng có vòng sáng bên ngoài.
class _BusMarker extends StatelessWidget {
  const _BusMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: RoutePalette.blue.withValues(alpha: 0.18),
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: RoutePalette.amber,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3310224A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            size: 20,
            color: RoutePalette.navy,
          ),
        ),
      ],
    );
  }
}