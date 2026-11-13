import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/parent_home_page.dart';
import 'package:mobile_app/features/trips/presentation/pages/parent/parent_trip_tracking_page.dart';
import 'package:mobile_app/features/alerts/presentation/pages/parent/parent_notifications_page.dart';
import 'package:mobile_app/features/alerts/presentation/pages/parent/absence_page.dart';
import 'package:mobile_app/features/profile/presentation/pages/parent/parent_profile_page.dart';

/// Tab đang mở lấy từ parentTabProvider (thay cho _currentIndex cục bộ),
/// nhờ vậy các nút go(1), go(2)... ở Trang chủ mới chuyển được tab.
class ParentShell extends ConsumerWidget {
  const ParentShell({super.key});

  static const List<Widget> _pages = [
    ParentHomePage(), // Tab 0: Trang chủ
    ParentTripTrackingPage(), // Tab 1: Theo dõi xe
    ParentNotificationsPage(), // Tab 2: Thông báo
    AbsencePage(), // Tab 3: Xin nghỉ học
    ParentProfilePage(), // Tab 4: Hồ sơ cá nhân
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = ref.watch(parentTabProvider);

    return Scaffold(
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(width: 1, color: Color(0xFFDDE6F5)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(ref, index, 0, 'Trang chủ', Icons.home),
            _buildNavItem(ref, index, 1, 'Theo dõi', Icons.location_on),
            _buildNavItem(ref, index, 2, 'Thông báo', Icons.notifications),
            _buildNavItem(ref, index, 3, 'Xin nghỉ', Icons.calendar_today),
            _buildNavItem(ref, index, 4, 'Hồ sơ', Icons.person),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    WidgetRef ref,
    int current,
    int index,
    String label,
    IconData icon,
  ) {
    final isSelected = current == index;

    return Expanded(
      child: InkWell(
        onTap: () => ref.read(parentTabProvider.notifier).go(index),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0ECFF) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF52628A),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF52628A),
                  fontSize: 11,
                  fontFamily: 'Be Vietnam Pro',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}