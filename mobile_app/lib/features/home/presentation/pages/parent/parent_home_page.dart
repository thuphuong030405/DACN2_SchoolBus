import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/home_theme.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/phone_call.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/trip_selection.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/trip_view_logic.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/contact_card.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/home_hero_card.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/home_widgets.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/trip_details_card.dart';
import 'package:mobile_app/features/home/presentation/widgets/parents/trip_timeline.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/students/presentation/pages/parent/link_child_page.dart';

// =============================================================================
// Trang chủ phụ huynh. File này chỉ ghép màn hình; logic ở trip_view_logic.dart,
// các thành phần giao diện ở thư mục widgets/.
// =============================================================================

class ParentHomePage extends ConsumerWidget {
  const ParentHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);
    final profile = ref.watch(myProfileProvider).asData?.value;

    return Scaffold(
      backgroundColor: HomeColors.bg,
      body: childrenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Không tải được dữ liệu: $e',
                    textAlign: TextAlign.center,
                    style: homeText(14, FontWeight.w400, HomeColors.redText)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(childrenProvider),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (all) {
          final approved = all.where((c) => c.isApproved).toList();
          final selected = ref.watch(selectedChildProvider);
          if (selected == null) return _EmptyState(pendingCount: all.length);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(childrenProvider);
              ref.invalidate(myProfileProvider);
              ref.invalidate(todayTripsProvider(selected.studentId));
            },
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _HomeBody(
                  parentName: profile?.fullName,
                  children: approved,
                  child: selected,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------- chưa liên kết / chờ duyệt

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.pendingCount});
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: HomeColors.blueSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.child_care, size: 40, color: HomeColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              pendingCount > 0
                  ? 'Yêu cầu liên kết đang chờ nhà trường duyệt'
                  : 'Bạn chưa liên kết với học sinh nào',
              textAlign: TextAlign.center,
              style: homeText(16, FontWeight.w600, HomeColors.ink),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: HomeColors.primaryMid,
                minimumSize: const Size(200, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Liên kết con'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LinkChildPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Nội dung chính: banner gradient + thẻ trạng thái + các mục bên dưới
// =============================================================================

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({
    required this.parentName,
    required this.children,
    required this.child,
  });
  final String? parentName;
  final List<ChildInfo> children;
  final ChildInfo child;

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final tripsAsync = ref.watch(todayTripsProvider(child.studentId));
    final rawTrips = tripsAsync.asData?.value ?? const <TodayTrip>[];

    // Khử lặp chuyến xe bằng map theo tripId
    final map = <String, TodayTrip>{};
    for (final t in rawTrips) {
      map[t.tripId] = t;
    }
    final trips = map.values.toList();

    final pickedTripId = ref.watch(selectedTripIdProvider); // dùng chung với tab Theo dõi
    final trip = trips.isEmpty
        ? null
        : (trips.where((t) => t.tripId == pickedTripId).firstOrNull ??
            pickFeaturedTrip(trips));
    final top = MediaQuery.of(context).padding.top;
    final hm = DateFormat('HH:mm');

    Widget hero;
    if (trip != null) {
      hero = HomeHeroCard(child: child, trip: trip);
    } else if (tripsAsync.hasError && !tripsAsync.hasValue) {
      hero = HomeCard(
        child: Column(
          children: [
            Text('Không tải được chuyến xe: ${tripsAsync.error}',
                style: homeText(13, FontWeight.w400, HomeColors.redText)),
            TextButton(
              onPressed: () => ref.invalidate(todayTripsProvider(child.studentId)),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    } else if (!tripsAsync.hasValue) {
      hero = const HomeCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      hero = HomeCard(
        child: Row(
          children: [
            HomeAvatar(text: nameInitials(child.fullName)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(child.fullName,
                      style: homeText(16, FontWeight.w700, HomeColors.ink)),
                  const SizedBox(height: 2),
                  Text('Hôm nay con không có chuyến xe nào.',
                      style: homeText(13, FontWeight.w600, HomeColors.muted)),
                  Text('Lịch xe sẽ hiện ở đây khi nhà trường phân tuyến cho bé.',
                      style: homeText(12, FontWeight.w400, HomeColors.muted, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ------------------------------------------------------------ banner
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [HomeColors.primary, HomeColors.primaryMid, HomeColors.primaryLight],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Stack(
            children: [
              const Positioned(right: -50, top: -50, child: HomeCircle(size: 190, alpha: 0x14)),
              const Positioned(left: -40, bottom: 90, child: HomeCircle(size: 110, alpha: 0x10)),
              Padding(
                padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(timeGreeting(),
                                  style: homeText(14, FontWeight.w400, const Color(0xFFDBE8FF))),
                              const SizedBox(height: 2),
                              Text(
                                (widget.parentName == null || widget.parentName!.isEmpty)
                                    ? 'Phụ huynh'
                                    : widget.parentName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: homeText(26, FontWeight.w700, Colors.white),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Material(
                          color: const Color(0x26FFFFFF),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => ref.read(parentTabProvider.notifier).go(2),
                            child: const SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(Icons.notifications_none_rounded, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.children.length > 1) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in widget.children)
                            HomePill(
                              label: c.fullName,
                              selected: c.studentId == child.studentId,
                              onTap: () => ref
                                  .read(selectedChildIdProvider.notifier)
                                  .select(c.studentId),
                            ),
                        ],
                      ),
                    ],
                    if (trips.length > 1 && trip != null) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in trips)
                            HomePill(
                              icon: Icons.directions_bus_rounded,
                              label: '${t.tripTypeLabel} · ${hm.format(t.startAt)}',
                              selected: t.tripId == trip.tripId,
                              onTap: () => ref.read(selectedTripIdProvider.notifier).select(t.tripId),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    hero,
                  ],
                ),
              ),
            ],
          ),
        ),

        // ------------------------------------------------------ các mục dưới
        if (trip != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (trip.attendanceStatus == 'BOARDED' && trip.tripStatus == 'COMPLETED') ...[
                  HomeBanner(
                    icon: Icons.warning_amber_rounded,
                    bg: HomeColors.redSoft,
                    fg: HomeColors.redText,
                    text: 'Chuyến đã kết thúc nhưng chưa ghi nhận bé xuống xe. '
                        'Hãy liên hệ cô giáo ngay.',
                    actionLabel: 'Gọi cô giáo',
                    onAction: () => callPhone(context, trip.teacherPhone),
                  ),
                  const SizedBox(height: 16),
                ],
                if (trip.attendanceStatus == 'ABSENT') ...[
                  const HomeBanner(
                    icon: Icons.event_busy_rounded,
                    bg: HomeColors.blueSoft,
                    fg: HomeColors.primary,
                    text: 'Bé nghỉ học buổi này. Điểm dừng của bé đã được bỏ khỏi lộ trình.',
                  ),
                  const SizedBox(height: 16),
                ],
                if (!trip.isActive && trip.tripStatus == 'COMPLETED') ...[
                  LatestTripCard(trip: trip),
                  const SizedBox(height: 22),
                ],
                const HomeSectionTitle('Hành trình hôm nay'),
                HomeCard(child: TripTimeline(steps: buildTripSteps(trip))),
                const SizedBox(height: 22),
                const HomeSectionTitle('Liên hệ nhanh'),
                Row(
                  children: [
                    Expanded(
                      child: ContactCard(
                        role: 'Cô giáo',
                        name: trip.teacherName,
                        phone: trip.teacherPhone,
                        icon: Icons.school_outlined,
                        bg: HomeColors.blueSoft,
                        fg: HomeColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ContactCard(
                        role: 'Tài xế',
                        name: trip.driverName,
                        phone: trip.driverPhone,
                        icon: Icons.drive_eta_outlined,
                        bg: HomeColors.yellowSoft,
                        fg: HomeColors.yellowText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const HomeSectionTitle('Chi tiết chuyến'),
                HomeCard(child: TripDetailsCard(trip: trip)),
              ],
            ),
          )
        else
          const SizedBox(height: 28),
      ],
    );
  }
}
