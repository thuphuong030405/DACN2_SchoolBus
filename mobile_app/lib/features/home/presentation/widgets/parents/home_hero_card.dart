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

class _HomeHeroCardState extends ConsumerState<HomeHeroCard>
    with SingleTickerProviderStateMixin {
  Timer? _ticker;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Tính lại tiến độ chuyến và việc mất tín hiệu GPS mỗi 5 giây
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });

    // Hiệu ứng nhịp thở (pulse) cho tín hiệu GPS trực tiếp
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulseController.dispose();
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
    ].join(' • ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: trip.isActive
              ? [
                  Colors.white,
                  const Color(0xFFF4F8FF),
                  const Color(0xFFEBF3FF),
                ]
              : [
                  Colors.white,
                  const Color(0xFFF8FAFC),
                ],
        ),
        border: Border.all(
          color: trip.isActive
              ? HomeColors.primaryMid.withValues(alpha: 0.22)
              : const Color(0xFFDCE6F7),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: (trip.isActive ? HomeColors.primaryMid : const Color(0xFF10224A))
                .withValues(alpha: 0.10),
            blurRadius: 24,
            spreadRadius: -2,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF10224A).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Họa tiết vòng tròn trang trí mờ tạo chiều sâu ở góc trên phải
            Positioned(
              right: -28,
              top: -28,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF08A).withValues(alpha: 0.45), // Vàng nhạt ấm áp
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: Avatar + Thông tin học sinh + Huy hiệu LIVE
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: trip.isActive
                                ? const [Color(0xFF3B82F6), Color(0xFFFACC15)]
                                : const [Color(0xFFCBD5E1), Color(0xFFE2E8F0)],
                          ),
                        ),
                        child: HomeAvatar(
                          text: nameInitials(child.fullName),
                          imageUrl: child.avatarUrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              child.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: homeText(16.5, FontWeight.w800, HomeColors.ink),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(
                                  Icons.directions_bus_filled_rounded,
                                  size: 13,
                                  color: trip.isActive
                                      ? HomeColors.primaryMid
                                      : HomeColors.muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: homeText(12, FontWeight.w500, HomeColors.muted),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (live) _buildLiveBadge(),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Khung trung tâm hiển thị Trạng thái & Thời gian dự kiến (ETA)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: s.chipBg.withValues(alpha: 0.9),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HomeStatusChip(text: s.chip, bg: s.chipBg, fg: s.chipFg),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            s.big,
                            style: homeText(36, FontWeight.w800, s.bigColor, height: 1.08),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          s.caption,
                          style: homeText(13.5, FontWeight.w500, HomeColors.muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Thanh tiến độ hành trình xe buýt
                  TripProgressBar(trip: trip, fraction: tripProgress(trip)),

                  const SizedBox(height: 18),

                  // 4. Hàng nút thao tác nhanh
                  Row(
                    children: [
                      if (trip.isActive) ...[
                        Expanded(
                          flex: 6,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2563EB).withValues(alpha: 0.34),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              onPressed: () =>
                                  ref.read(parentTabProvider.notifier).go(1),
                              icon: const Icon(Icons.near_me_rounded, size: 18),
                              label: Text(
                                'Xem vị trí xe',
                                style: homeText(13.5, FontWeight.w700, Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: HomeColors.primaryMid,
                              side: BorderSide(
                                color: HomeColors.primaryMid.withValues(alpha: 0.35),
                                width: 1.3,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            onPressed: () => callPhone(context, trip.teacherPhone),
                            icon: const Icon(Icons.call_rounded, size: 18),
                            label: Text(
                              'Gọi cô giáo',
                              style: homeText(13.5, FontWeight.w700, HomeColors.primaryMid),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Huy hiệu LIVE có hiệu ứng vòng sóng nhấp nháy
  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: HomeColors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: HomeColors.green.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final scale = 0.85 + (_pulseController.value * 0.35);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: HomeColors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: HomeColors.green.withValues(alpha: 0.55),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            'TRỰC TIẾP',
            style: homeText(10.5, FontWeight.w800, HomeColors.green),
          ),
        ],
      ),
    );
  }
}

/// Thanh tiến độ chuyến: xe buýt vàng chạy dọc lộ trình từ điểm xuất phát đến điểm đích.
class TripProgressBar extends StatelessWidget {
  const TripProgressBar({super.key, required this.trip, required this.fraction});
  final TodayTrip trip;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final hm = DateFormat('HH:mm');
    final safeFraction = fraction.clamp(0.0, 1.0);

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, c) {
            const busSize = 34.0;
            final track = (c.maxWidth - busSize).clamp(0.0, double.infinity);

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: safeFraction),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, f, _) {
                final left = track * f;
                return SizedBox(
                  height: busSize,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Đường ray nền
                      Container(
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F5),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),

                      // Điểm mốc xuất phát (bên trái)
                      Positioned(
                        left: 4,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Phần đường đã đi qua (gradient xanh dương)
                      Container(
                        height: 9,
                        width: left + busSize / 2,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1D4ED8), Color(0xFF60A5FA)],
                          ),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),

                      // Điểm mốc đích đến (bên phải)
                      Positioned(
                        right: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: f >= 0.98
                                ? Colors.white
                                : HomeColors.primaryMid.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Icon xe buýt vàng School Bus di chuyển
                      Positioned(
                        left: left,
                        child: Container(
                          width: busSize,
                          height: busSize,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFDE047), Color(0xFFFACC15)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEAB308).withValues(alpha: 0.42),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            size: 17,
                            color: Color(0xFF0F172A),
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.play_circle_outline_rounded,
                    size: 13, color: HomeColors.muted),
                const SizedBox(width: 4),
                Text(
                  'Xuất phát ${hm.format(trip.startAt)}',
                  style: homeText(11.5, FontWeight.w500, HomeColors.muted),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 13, color: HomeColors.primaryMid),
                const SizedBox(width: 4),
                Text(
                  'Dự kiến ${hm.format(trip.endAt)}',
                  style: homeText(11.5, FontWeight.w600, HomeColors.ink),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}