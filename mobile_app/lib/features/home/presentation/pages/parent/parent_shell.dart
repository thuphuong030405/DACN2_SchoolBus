import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      extendBody: true, // Giúp nội dung nền trôi mượt phía dưới thanh dock nổi
      body: IndexedStack(index: index, children: _pages),
      bottomNavigationBar: _ParentBottomNavigation(
        currentIndex: index,
        onTap: (selectedIndex) =>
            ref.read(parentTabProvider.notifier).go(selectedIndex),
      ),
    );
  }
}

class _ParentBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ParentBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF1D4ED8);
  static const Color _busYellow = Color(0xFFFACC15);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        bottomPadding > 0 ? bottomPadding : 10,
      ),
      child: SizedBox(
        height: 84,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 1. Khung nền nổi bo góc + vòm sóng mềm mại ở giữa
            Positioned.fill(
              child: CustomPaint(
                painter: _ParentFloatingWavePainter(
                  backgroundColor: Colors.white,
                  borderColor: const Color(0xFFDCE6F7),
                  shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.14),
                ),
              ),
            ),

            // 2. Hàng 5 mục menu
            SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSideItem(
                    index: 0,
                    icon: Icons.home_outlined,
                    selectedIcon: Icons.home_rounded,
                    label: 'Trang chủ',
                  ),
                  _buildSideItem(
                    index: 1,
                    icon: Icons.location_on_outlined,
                    selectedIcon: Icons.location_on_rounded,
                    label: 'Theo dõi',
                  ),
                  _buildCenterNotificationHub(),
                  _buildSideItem(
                    index: 3,
                    icon: Icons.event_busy_outlined,
                    selectedIcon: Icons.event_busy_rounded,
                    label: 'Xin nghỉ',
                  ),
                  _buildSideItem(
                    index: 4,
                    icon: Icons.person_outline_rounded,
                    selectedIcon: Icons.person_rounded,
                    label: 'Hồ sơ',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 4 tab hai bên với hiệu ứng nảy nhẹ & font Be Vietnam Pro
  Widget _buildSideItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap(index);
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7, top: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                padding: EdgeInsets.symmetric(
                  horizontal: isSelected ? 13 : 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? _primaryColor.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: AnimatedScale(
                  scale: isSelected ? 1.12 : 1.0,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutBack,
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    size: 22,
                    color: isSelected ? _primaryDark : _textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: isSelected ? 11.5 : 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? _primaryDark : _textMuted,
                  letterSpacing: 0.1,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNotificationHub() {
    final bool isSelected = currentIndex == 2;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(2);
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // 1. Vòng hào quang bên ngoài: xanh nhạt đồng bộ
                    OverflowBox(
                      maxWidth: 60,
                      maxHeight: 60,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 58 : 54,
                        height: isSelected ? 58 : 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _primaryColor.withValues(alpha: 0.14)
                              : const Color(0xFFDBEAFE).withValues(alpha: 0.55),
                        ),
                      ),
                    ),

                    // 2. Nút tròn chính bên trong: nền xanh nhạt ban đầu (#EFF6FF -> #DBEAFE)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutBack,
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isSelected
                              ? const [Color(0xFF3B82F6), _primaryDark]
                              : const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? _primaryColor.withValues(alpha: 0.42)
                                : const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                            blurRadius: isSelected ? 14 : 8,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.notifications_rounded
                            : Icons.notifications_outlined,
                        size: 23,
                        color: isSelected ? Colors.white : _primaryDark,
                      ),
                    ),

                    // 3. Chấm nhấn màu vàng School Bus
                    Positioned(
                      top: 2,
                      right: 2,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: isSelected ? 11 : 9,
                        height: isSelected ? 11 : 9,
                        decoration: BoxDecoration(
                          color: _busYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Thông báo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Be Vietnam Pro',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _primaryDark : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vẽ thanh dock nổi bo tròn 4 góc + vòm sóng cong mượt ôm lấy tab Thông báo ở giữa
class _ParentFloatingWavePainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;

  _ParentFloatingWavePainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double baseTop = 16.0;
    const double bumpHeight = 14.0;
    const double curveHalfWidth = 60.0;
    const double cornerRadius = 24.0;

    final double centerX = size.width / 2;

    final Path path = Path()
      ..moveTo(0, baseTop + cornerRadius)
      ..quadraticBezierTo(0, baseTop, cornerRadius, baseTop)
      ..lineTo(centerX - curveHalfWidth, baseTop)
      ..cubicTo(
        centerX - curveHalfWidth * 0.56,
        baseTop,
        centerX - curveHalfWidth * 0.42,
        baseTop - bumpHeight,
        centerX,
        baseTop - bumpHeight,
      )
      ..cubicTo(
        centerX + curveHalfWidth * 0.42,
        baseTop - bumpHeight,
        centerX + curveHalfWidth * 0.56,
        baseTop,
        centerX + curveHalfWidth,
        baseTop,
      )
      ..lineTo(size.width - cornerRadius, baseTop)
      ..quadraticBezierTo(size.width, baseTop, size.width, baseTop + cornerRadius)
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - cornerRadius,
        size.height,
      )
      ..lineTo(cornerRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
      ..close();

    canvas.drawShadow(path, shadowColor, 14, false);

    final Paint fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ParentFloatingWavePainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.shadowColor != shadowColor;
}