import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/home_theme.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/phone_call.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/trip_view_logic.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/home_widgets.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';

/// Thẻ trạng thái chính: tên con, trạng thái, thời gian tới, tiến độ chuyến, nút thao tác.
class HomeHeroCard extends ConsumerStatefulWidget {
  const HomeHeroCard({super.key, required this.child, required this.trip});
  final ChildInfo child;
  final TodayTrip trip;

  @override
  ConsumerState<HomeHeroCard> createState() => _HomeHeroCardState();
}

class _HomeHeroCardState extends ConsumerState<HomeHeroCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tính lại tiến độ chuyến và việc mất tín hiệu GPS mỗi 5 giây
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final child = widget.child;

    final gps = trip.isActive
        ? ref.watch(busLocationProvider(trip.tripId)).asData?.value
        : null;
    final stale = isGpsStale(gps);
    final live = trip.isActive && gps != null && !stale;
    final s = summarizeTrip(trip, gps, stale, child.fullName);

    final subtitle = [
      if (child.className != null) 'Lớp ${child.className}',
      if (tripRouteLabel(trip) != null) tripRouteLabel(trip)!,
      trip.tripTypeLabel,
    ].join(' · ');

    return HomeCard(
      padding: const EdgeInsets.all(18),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: homeText(16, FontWeight.w700, HomeColors.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: homeText(12, FontWeight.w400, HomeColors.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              HomeStatusChip(text: s.chip, bg: s.chipBg, fg: s.chipFg),
              if (live) ...[
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: HomeColors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text('Trực tiếp', style: homeText(12, FontWeight.w600, HomeColors.green)),
              ],
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(s.big, style: homeText(40, FontWeight.w800, s.bigColor, height: 1.1)),
          ),
          const SizedBox(height: 4),
          Text(s.caption, style: homeText(14, FontWeight.w400, HomeColors.muted, height: 1.4)),
          const SizedBox(height: 18),
          TripProgressBar(trip: trip, fraction: tripProgress(trip)),
          const SizedBox(height: 18),
          Row(
            children: [
              if (trip.isActive) ...[
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: HomeColors.primaryMid,
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => ref.read(parentTabProvider.notifier).go(1),
                    icon: const Icon(Icons.location_on, size: 18),
                    label: Text('Xem vị trí xe',
                        style: homeText(14, FontWeight.w700, Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: HomeColors.primaryMid,
                    side: const BorderSide(color: HomeColors.primaryMid),
                    minimumSize: const Size(0, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => callPhone(context, trip.teacherPhone),
                  icon: const Icon(Icons.call_outlined, size: 18),
                  label: Text('Gọi cô giáo',
                      style: homeText(14, FontWeight.w600, HomeColors.primaryMid)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thanh tiến độ chuyến: xe chạy dọc theo thời gian từ lúc xuất phát đến giờ dự kiến kết thúc.
class TripProgressBar extends StatelessWidget {
  const TripProgressBar({super.key, required this.trip, required this.fraction});
  final TodayTrip trip;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final hm = DateFormat('HH:mm');
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            const bus = 30.0;
            final track = c.maxWidth - bus;
            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, f, _) {
                final left = track * f;
                return SizedBox(
                  height: bus,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: HomeColors.blueSoft,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: left + bus / 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [HomeColors.primaryMid, HomeColors.primaryLight],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Positioned(
                        left: left,
                        child: Container(
                          width: bus,
                          height: bus,
                          decoration: const BoxDecoration(
                            color: HomeColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x401D4ED8),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Xuất phát ${hm.format(trip.startAt)}',
                style: homeText(12, FontWeight.w400, HomeColors.muted)),
            Text('Dự kiến đến ${hm.format(trip.endAt)}',
                style: homeText(12, FontWeight.w400, HomeColors.muted)),
          ],
        ),
      ],
    );
  }
}
