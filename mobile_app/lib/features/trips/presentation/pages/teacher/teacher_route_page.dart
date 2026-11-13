import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mobile_app/features/trips/domain/entities/trip_route_detail.dart';
import 'package:mobile_app/features/trips/domain/utils/geo_utils.dart';
import 'package:mobile_app/features/trips/presentation/providers/trip_provider.dart';
import 'package:mobile_app/features/trips/presentation/widgets/route_map.dart';
import 'package:mobile_app/features/trips/presentation/widgets/route_palette.dart';

class TeacherRoutePage extends ConsumerStatefulWidget {
  const TeacherRoutePage({super.key});

  static const Color primaryColor = RoutePalette.blue;

  @override
  ConsumerState<TeacherRoutePage> createState() => _TeacherRoutePageState();
}

class _TeacherRoutePageState extends ConsumerState<TeacherRoutePage> {
  static const double _mapHeight = 260;
  static const double _sheetOverlap = 24;

  final MapController _mapController = MapController();

  Timer? _refreshTimer;
  String? _selectedStopId;

  @override
  void initState() {
    super.initState();
    // Tự làm mới 30 giây/lần để theo dõi tiến độ xe.
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(teacherRouteDetailProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Chọn 1 điểm dừng (từ marker hoặc từ danh sách): đưa bản đồ tới điểm đó.
  void _selectStop(RouteStopInfo stop) {
    setState(() => _selectedStopId = stop.stopId);

    if (stop.hasLocation) {
      _mapController.move(LatLng(stop.latitude!, stop.longitude!), 16);
    }
  }

  /// Mở Google Maps chỉ đường tới điểm dừng.
  Future<void> _openDirections(RouteStopInfo stop) async {
    final destination = stop.hasLocation
        ? '${stop.latitude},${stop.longitude}'
        : Uri.encodeComponent('${stop.name}, ${stop.address}');

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không mở được ứng dụng bản đồ')),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final routeAsync = ref.watch(teacherRouteDetailProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: routeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _buildMessage(
            icon: Icons.wifi_off,
            title: 'Không tải được lộ trình',
            subtitle: 'Kiểm tra kết nối mạng rồi thử lại.',
            showRetry: true,
          ),
          data: (detail) {
            if (detail == null) {
              return _buildMessage(
                icon: Icons.directions_bus_outlined,
                title: 'Hôm nay bạn chưa có chuyến xe nào.',
              );
            }
            return _buildContent(detail);
          },
        ),
      ),
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String title,
    String? subtitle,
    bool showRetry = false,
  }) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(teacherRouteDetailProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 52, color: RoutePalette.outline),
          const SizedBox(height: 14),
          Center(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: RoutePalette.text(15, FontWeight.w700, RoutePalette.navy),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                subtitle,
                style:
                    RoutePalette.text(13, FontWeight.w400, RoutePalette.grey),
              ),
            ),
          ],
          if (showRetry) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => ref.invalidate(teacherRouteDetailProvider),
                child: const Text('Thử lại'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(TripRouteDetail detail) {
    // Chỉ hiện xe khi chuyến đang chạy và có toạ độ GPS.
    final busPosition =
        (detail.status == 'IN_PROGRESS' && detail.hasBusLocation)
            ? LatLng(detail.busLatitude!, detail.busLongitude!)
            : null;

    return Stack(
      children: [
        // ---------- Bản đồ ----------
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _mapHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: RouteMap(
                  stops: detail.stops,
                  controller: _mapController,
                  selectedStopId: _selectedStopId,
                  onStopTap: _selectStop,
                  busPosition: busPosition,
                  height: _mapHeight,
                  showLegend: false,
                  borderRadius: BorderRadius.zero,
                  infoTopOffset: 64,
                  controlsTopOffset: 64,
                  attributionBottomInset: _sheetOverlap + 4,
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: _buildSharingPill(detail.status),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(
                      Icons.refresh,
                      color: RoutePalette.blue,
                      size: 22,
                    ),
                    onPressed: () => ref.invalidate(teacherRouteDetailProvider),
                  ),
                ),
              ),
            ],
          ),
        ),

        // ---------- Bảng thông tin tuyến ----------
        Positioned(
          top: _mapHeight - _sheetOverlap,
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildSheet(detail),
        ),
      ],
    );
  }

  // =========================================================
  // PILL TRẠNG THÁI
  // =========================================================

  Widget _buildSharingPill(String status) {
    final (Color dot, String label) = switch (status) {
      'IN_PROGRESS' => (RoutePalette.green, 'Đang chia sẻ vị trí'),
      'COMPLETED' => (RoutePalette.blue, 'Chuyến đã hoàn thành'),
      'CANCELLED' => (RoutePalette.red, 'Chuyến đã huỷ'),
      _ => (RoutePalette.outline, 'Chưa xuất phát'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadows: const [
          BoxShadow(
            color: Color(0x2310224A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: RoutePalette.text(13, FontWeight.w600, RoutePalette.navy),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SHEET: HEADER + DANH SÁCH + NÚT CHỈ ĐƯỜNG
  // =========================================================

  Widget _buildSheet(TripRouteDetail detail) {
    final stops = detail.stops;
    final passedCount = stops.where((s) => s.isCompleted).length;
    final nextStop = stops.where((s) => s.isNext).firstOrNull;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1410224A),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSheetHeader(detail, passedCount),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.refresh(teacherRouteDetailProvider.future),
              child: stops.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Tuyến này chưa có điểm dừng.',
                            style: RoutePalette.text(
                              13,
                              FontWeight.w400,
                              RoutePalette.grey,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: stops.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (_, index) => _buildStopRow(
                        stop: stops[index],
                        index: index,
                        isLast: index == stops.length - 1,
                      ),
                    ),
            ),
          ),
          if (nextStop != null) ...[
            const SizedBox(height: 10),
            _buildDirectionsButton(nextStop),
          ],
        ],
      ),
    );
  }

  Widget _buildSheetHeader(TripRouteDetail detail, int passedCount) {
    final typeLabel = detail.tripType == 'MORNING' ? 'Đón sáng' : 'Trả chiều';
    final endLabel = detail.tripType == 'MORNING' ? 'đến trường' : 'kết thúc';

    final km = routeDistanceKm([
      for (final s in detail.stops)
        if (s.hasLocation) (s.latitude!, s.longitude!),
    ]);

    final parts = <String>[
      '${detail.stops.length} điểm dừng',
      if (detail.totalStudents > 0) '${detail.totalStudents} học sinh',
      if (km != null) '${km.toStringAsFixed(1).replaceAll('.', ',')} km',
      '$endLabel ${_hm(detail.endAt)}',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${detail.routeName} · $typeLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RoutePalette.text(
                    20,
                    FontWeight.w700,
                    RoutePalette.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  parts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RoutePalette.text(
                    13,
                    FontWeight.w400,
                    RoutePalette.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildBadge(
            '$passedCount/${detail.stops.length}',
            RoutePalette.blueLight,
            RoutePalette.blueDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        text,
        style: RoutePalette.text(12, FontWeight.w600, foreground),
      ),
    );
  }

  // =========================================================
  // 1 DÒNG ĐIỂM DỪNG
  // =========================================================

  Widget _buildStopRow({
    required RouteStopInfo stop,
    required int index,
    required bool isLast,
  }) {
    final passed = stop.isCompleted;
    final isNext = stop.isNext;
    final selected = stop.stopId == _selectedStopId;

    // Điểm đến (trường) -> "Điểm đến"; các điểm khác -> số học sinh.
    // Đếm theo student_id nên chị em sinh đôi cùng nhà vẫn ra "2 HS".
    Widget? badge;
    if (isLast) {
      badge = _buildBadge(
        'Điểm đến',
        RoutePalette.greenLight,
        RoutePalette.greenDark,
      );
    } else if (stop.studentCount > 0) {
      badge = _buildBadge(
        '${stop.studentCount} HS',
        RoutePalette.blueLight,
        RoutePalette.blueDark,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectStop(stop),
      child: Container(
        width: double.infinity,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: ShapeDecoration(
          color: isNext ? RoutePalette.amberLight : null,
          shape: RoundedRectangleBorder(
            side: selected
                ? const BorderSide(color: RoutePalette.blue, width: 1.5)
                : BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            _buildStepCircle(index: index, passed: passed, isNext: isNext),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                stop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RoutePalette.text(
                  14,
                  FontWeight.w700,
                  RoutePalette.navy,
                ),
              ),
            ),
            if (stop.estimatedTime != null) ...[
              const SizedBox(width: 8),
              Text(
                stop.estimatedTime!,
                style: RoutePalette.text(
                  12,
                  FontWeight.w400,
                  RoutePalette.grey,
                ),
              ),
            ],
            if (badge != null) ...[
              const SizedBox(width: 8),
              badge,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepCircle({
    required int index,
    required bool passed,
    required bool isNext,
  }) {
    if (passed) {
      return Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: RoutePalette.blue,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: Colors.white, size: 15),
      );
    }

    if (isNext) {
      return Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: RoutePalette.amber,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${index + 1}',
          style: RoutePalette.text(13, FontWeight.w700, RoutePalette.navy),
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: RoutePalette.outline, width: 2),
      ),
      child: Text(
        '${index + 1}',
        style: RoutePalette.text(13, FontWeight.w700, RoutePalette.grey),
      ),
    );
  }

  // =========================================================
  // NÚT CHỈ ĐƯỜNG
  // =========================================================

  Widget _buildDirectionsButton(RouteStopInfo stop) {
    return Material(
      color: RoutePalette.blue,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDirections(stop),
        child: Container(
          width: double.infinity,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.navigation_outlined,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Mở chỉ đường tới ${stop.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RoutePalette.text(16, FontWeight.w700, Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}