import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/home_theme.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/trip_selection.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/trip_view_logic.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/home_widgets.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/phone_call.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/trip_timeline.dart';
// =============================================================================
// Trang Theo dõi chuyến đi. Dùng CHUNG logic với Trang chủ (summarizeTrip, buildTripSteps,
// isGpsStale, selectedTripIdProvider) nên hai tab luôn hiển thị cùng một câu chuyện.
// =============================================================================

class ParentTripTrackingPage extends ConsumerWidget {
  const ParentTripTrackingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    if (child == null) {
      return Scaffold(
        backgroundColor: HomeColors.bg,
        body: Center(
          child: Text('Chưa có học sinh được liên kết',
              style: homeText(14, FontWeight.w600, HomeColors.ink)),
        ),
      );
    }

    final tripsAsync = ref.watch(todayTripsProvider(child.studentId));
    return Scaffold(
      backgroundColor: HomeColors.bg,
      body: tripsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lỗi tải chuyến xe: $e',
                    textAlign: TextAlign.center,
                    style: homeText(14, FontWeight.w400, HomeColors.redText)),
                TextButton(
                  onPressed: () => ref.invalidate(todayTripsProvider(child.studentId)),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (raw) {
          final trips = {for (final t in raw) t.tripId: t}.values.toList(); // khử lặp
          if (trips.isEmpty) {
            return Center(
              child: Text('Hôm nay con không có chuyến xe nào',
                  style: homeText(14, FontWeight.w500, HomeColors.muted)),
            );
          }
          final pickedId = ref.watch(selectedTripIdProvider);
          final trip = trips.where((t) => t.tripId == pickedId).firstOrNull ??
              pickFeaturedTrip(trips);
          // key theo chuyến: đổi chuyến thì khởi tạo lại bản đồ và vị trí xe
          return _TrackingView(
            key: ValueKey(trip.tripId),
            child: child,
            trip: trip,
            trips: trips,
          );
        },
      ),
    );
  }
}

class _TrackingView extends ConsumerStatefulWidget {
  const _TrackingView({
    super.key,
    required this.child,
    required this.trip,
    required this.trips,
  });
  final ChildInfo child;
  final TodayTrip trip;
  final List<TodayTrip> trips;

  @override
  ConsumerState<_TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends ConsumerState<_TrackingView>
    with SingleTickerProviderStateMixin {
  static const _fallbackCenter = LatLng(16.0544, 108.2022); // chỉ dùng khi chuyến chưa có tọa độ nào

  final _map = MapController();
  late final AnimationController _anim;
  Timer? _ticker;
  bool _ready = false;
  bool _follow = true; // bản đồ tự bám theo xe, tắt khi người dùng tự kéo bản đồ

  LatLng? _from;
  LatLng? _to;
  LatLng? _pos; // vị trí xe đang hiển thị (đã làm mượt)

  @override
  void initState() {
    super.initState();
    // MỘT animation + MỘT listener duy nhất (tránh tích lũy listener mỗi lần có điểm GPS mới)
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..addListener(_onTick);
    // Cập nhật "cách đây bao lâu" và việc mất tín hiệu GPS
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _anim.dispose();
    _map.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------- vị trí xe

  void _onTick() {
    final a = _from, b = _to;
    if (a == null || b == null) return;
    final t = Curves.easeInOut.transform(_anim.value);
    final p = LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
    setState(() => _pos = p);
    if (_follow && _ready) _map.move(p, _map.camera.zoom);
  }

  void _onGps(GpsPoint p) {
    final target = LatLng(p.lat, p.lng);
    final cur = _pos;
    if (cur == null) {
      // Điểm GPS đầu tiên: đặt thẳng vị trí, KHÔNG lướt từ tọa độ mặc định
      setState(() {
        _pos = target;
        _from = target;
        _to = target;
      });
      _recenter();
      return;
    }
    if (distanceMeters(cur.latitude, cur.longitude, target.latitude, target.longitude) < 2) {
      return; // nhiễu GPS khi xe đứng yên
    }
    _from = cur;
    _to = target;
    _anim.forward(from: 0);
  }

  // ---------------------------------------------------------------- điểm dừng

  LatLng? _point(double? lat, double? lng) =>
      (lat == null || lng == null) ? null : LatLng(lat, lng);

  LatLng? get _pickup => _point(widget.trip.pickupLat, widget.trip.pickupLng);
  LatLng? get _dropoff => _point(widget.trip.dropoffLat, widget.trip.dropoffLng);

  /// Xe đang hướng tới: chưa lên xe -> điểm đón; đang trên xe -> điểm trả.
  LatLng? get _target => widget.trip.attendanceStatus == 'BOARDED' ? _dropoff : _pickup;

  double _zoomFor(double m) {
    if (m < 400) return 16.5;
    if (m < 900) return 15.5;
    if (m < 1800) return 14.5;
    if (m < 3500) return 13.5;
    if (m < 7000) return 12.5;
    return 11.5;
  }

  /// Đưa bản đồ về vị trí xe + điểm đang hướng tới.
  void _recenter() {
    if (!_ready) return;
    final bus = _pos;
    final stop = _target ?? _pickup ?? _dropoff;
    if (bus == null && stop == null) return;
    if (bus == null) {
      _map.move(stop!, 15.5);
      return;
    }
    if (stop == null) {
      _map.move(bus, 16);
      return;
    }
    final m = distanceMeters(bus.latitude, bus.longitude, stop.latitude, stop.longitude);
    _map.move(
      LatLng((bus.latitude + stop.latitude) / 2, (bus.longitude + stop.longitude) / 2),
      _zoomFor(m),
    );
  }

  // ------------------------------------------------------------------- giao diện

  Marker _stopMarker(LatLng p, String label, Color color) => Marker(
        point: p,
        width: 96,
        height: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Text(label, style: homeText(11, FontWeight.w700, HomeColors.ink)),
            ),
            Icon(Icons.location_on, size: 32, color: color),
          ],
        ),
      );

  Marker _busMarker(LatLng p) => Marker(
        point: p,
        width: 52,
        height: 52,
        child: Container(
          decoration: BoxDecoration(
            color: HomeColors.yellow,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: const Icon(Icons.directions_bus_rounded, size: 28, color: HomeColors.ink),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final child = widget.child;
    final active = trip.isActive;
    final top = MediaQuery.of(context).padding.top;

    final gps = active ? ref.watch(busLocationProvider(trip.tripId)).asData?.value : null;
    if (active) {
      ref.listen(busLocationProvider(trip.tripId), (prev, next) {
        final p = next.asData?.value;
        if (p != null) _onGps(p);
      });
    }
    // ref.listen không bắn cho giá trị đã có sẵn lúc mở màn hình -> khởi tạo vị trí từ đó
    if (gps != null && _pos == null) {
      _pos = LatLng(gps.lat, gps.lng);
      _from = _pos;
      _to = _pos;
    }

    final stale = isGpsStale(gps);
    final s = summarizeTrip(trip, gps, stale, child.fullName);
    final secs = gps == null ? null : DateTime.now().difference(gps.recordedAt).inSeconds;
    final target = _target;
    final showLine = active &&
        _pos != null &&
        target != null &&
        (trip.attendanceStatus == 'PENDING' || trip.attendanceStatus == 'BOARDED');

    final route = tripRouteLabel(trip);
    final subtitle = [
      if (child.className != null) 'Lớp ${child.className}',
      if (route != null) route,
      trip.tripTypeLabel,
    ].join(' · ');

    return Stack(
      children: [
        // -------------------------------------------------------------- bản đồ
        Positioned.fill(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _pos ?? _target ?? _pickup ?? _dropoff ?? _fallbackCenter,
              initialZoom: 15.5,
              onMapReady: () {
                _ready = true;
                _recenter();
              },
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _follow) setState(() => _follow = false);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mobile_app',
              ),
              if (showLine)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_pos!, target],
                      strokeWidth: 4,
                      color: const Color(0x992563EB),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_pickup != null) _stopMarker(_pickup!, 'Điểm đón', HomeColors.red),
                  if (_dropoff != null) _stopMarker(_dropoff!, 'Điểm trả', HomeColors.ink),
                  if (_pos != null) _busMarker(_pos!),
                ],
              ),
            ],
          ),
        ),

        // ------------------------------------------------- thẻ con + chọn chuyến
        Positioned(
          top: top + 12,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Color(0x2310224A), blurRadius: 10, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    HomeAvatar(text: nameInitials(child.fullName), imageUrl: child.avatarUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: homeText(15, FontWeight.w700, HomeColors.ink)),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: homeText(12, FontWeight.w400, HomeColors.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.trips.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final t in widget.trips) ...[
                        _TripChip(
                          label: t.tripTypeLabel,
                          selected: t.tripId == trip.tripId,
                          onTap: () => ref.read(selectedTripIdProvider.notifier).select(t.tripId),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // ------------------------------------------------ nút về vị trí xe
        if (!_follow && _pos != null)
          Positioned(
            right: 16,
            top: top + (widget.trips.length > 1 ? 140 : 100),
            child: FloatingActionButton.small(
              heroTag: null,
              backgroundColor: Colors.white,
              foregroundColor: HomeColors.primaryMid,
              onPressed: () {
                setState(() => _follow = true);
                _recenter();
              },
              child: const Icon(Icons.my_location),
            ),
          ),

        // ----------------------------------------------- thẻ chi tiết (kéo lên/xuống)
        DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.28,
          maxChildSize: 0.88,
          builder: (context, scroll) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, -4))],
            ),
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: HomeColors.greySoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    HomeStatusChip(text: s.chip, bg: s.chipBg, fg: s.chipFg),
                    const Spacer(),
                    Text(
                      gps == null
                          ? (active ? 'Đang chờ GPS...' : '')
                          : 'Cập nhật ${agoLabel(secs ?? 0)}',
                      style: homeText(
                        12,
                        FontWeight.w400,
                        stale ? HomeColors.red : HomeColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(s.big, style: homeText(36, FontWeight.w800, s.bigColor, height: 1.1)),
                ),
                const SizedBox(height: 4),
                Text(s.caption,
                    style: homeText(14, FontWeight.w400, HomeColors.muted, height: 1.4)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _InfoTile(label: 'Biển số', value: trip.licensePlate)),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoTile(label: 'Cô giáo', value: trip.teacherName)),
                    const SizedBox(width: 8),
                    Expanded(child: _InfoTile(label: 'Tài xế', value: trip.driverName)),
                  ],
                ),
                const SizedBox(height: 18),
                TripTimeline(steps: buildTripSteps(trip)),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeColors.primary,
                    side: const BorderSide(color: HomeColors.primary, width: 1.2),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => callPhone(context, trip.teacherPhone),
                  icon: const Icon(Icons.phone_outlined, size: 20),
                  label: Text('Gọi cô giáo', style: homeText(15, FontWeight.w700, HomeColors.primary)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TripChip extends StatelessWidget {
  const _TripChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? HomeColors.primaryMid : HomeColors.blueSoft,
        shape: const StadiumBorder(),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Text(
              label,
              style: homeText(12, FontWeight.w600, selected ? Colors.white : HomeColors.primary),
            ),
          ),
        ),
      );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: HomeColors.bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: homeText(11, FontWeight.w400, HomeColors.muted)),
            const SizedBox(height: 2),
            Text(
              value.isNotEmpty ? value : '---',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: homeText(13, FontWeight.w700, HomeColors.ink),
            ),
          ],
        ),
      );
}
