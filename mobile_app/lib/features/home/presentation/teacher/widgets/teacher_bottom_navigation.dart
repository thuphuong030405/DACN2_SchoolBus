import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeacherBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TeacherBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color _primaryColor = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF1E40AF);
  static const Color _busYellow = Color(0xFFFACC15);
  static const Color _dangerColor = Color(0xFFEF4444);
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
        height: 84, // Tăng nhẹ từ 82 -> 84 cho thoáng
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // 1. Khung nền nổi bo góc + vòm sóng mềm mại ở giữa
            Positioned.fill(
              child: CustomPaint(
                painter: _FloatingWaveNavPainter(
                  backgroundColor: Colors.white,
                  borderColor: const Color(0xFFDCE6F7),
                  shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.14),
                ),
              ),
            ),

            // 2. Hàng 5 mục menu (chiều cao 84 khớp với khung ngoài, không bao giờ overflow)
            SizedBox(
              height: 84,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildSideItem(
                    index: 0,
                    icon: Icons.directions_bus_outlined,
                    selectedIcon: Icons.directions_bus_rounded,
                    label: 'Chuyến xe',
                  ),
                  _buildSideItem(
                    index: 1,
                    icon: Icons.explore_outlined,
                    selectedIcon: Icons.explore_rounded,
                    label: 'Lộ trình',
                  ),
                  _buildCenterAttendanceHub(),
                  _buildSideItem(
                    index: 3,
                    icon: Icons.notifications_active_outlined,
                    selectedIcon: Icons.warning_rounded,
                    label: 'SOS',
                    isDanger: true,
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

  /// 4 tab hai bên với hiệu ứng nảy nhẹ + thanh chỉ báo (pill indicator) sinh động
  Widget _buildSideItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    bool isDanger = false,
  }) {
    final bool isSelected = currentIndex == index;
    final Color activeColor = isDanger ? _dangerColor : _primaryColor;

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
                      ? activeColor.withValues(alpha: 0.12)
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
                    color: isSelected ? activeColor : _textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: isSelected ? 11.5 : 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : _textMuted,
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

  /// Tab Điểm danh trung tâm: Nút tròn nổi 3D + chấm vàng School Bus tạo điểm nhấn
  /// Tab Điểm danh trung tâm: Nút tròn nổi 3D + chấm vàng School Bus
  Widget _buildCenterAttendanceHub() {
    final bool isSelected = currentIndex == 2;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap(2);
        },
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7), // Căn đáy thẳng hàng với 4 tab bên cạnh
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
                    // Vòng hào quang mềm xung quanh
                    OverflowBox(
                      maxWidth: 60,
                      maxHeight: 60,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 58 : 48,
                        height: isSelected ? 58 : 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _primaryColor.withValues(alpha: 0.14)
                              : Colors.transparent,
                        ),
                      ),
                    ),

                    // Nút chính gradient xanh dương
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
                            ? Icons.fact_check_rounded
                            : Icons.fact_check_outlined,
                        size: 23,
                        color: isSelected ? Colors.white : _primaryColor,
                      ),
                    ),

                    // Chấm nhấn màu vàng School Bus
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
                'Điểm danh',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? _primaryColor : _textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vẽ thanh dock nổi bo tròn 4 góc + đường sóng cong mượt ôm lấy nút Điểm danh ở giữa
class _FloatingWaveNavPainter extends CustomPainter {
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;

  _FloatingWaveNavPainter({
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
      // Góc trên trái bo tròn
      ..moveTo(0, baseTop + cornerRadius)
      ..quadraticBezierTo(0, baseTop, cornerRadius, baseTop)
      // Đoạn thẳng tới chân sóng bên trái
      ..lineTo(centerX - curveHalfWidth, baseTop)
      // Sóng cong lên ôm nút trung tâm
      ..cubicTo(
        centerX - curveHalfWidth * 0.56,
        baseTop,
        centerX - curveHalfWidth * 0.42,
        baseTop - bumpHeight,
        centerX,
        baseTop - bumpHeight,
      )
      // Sóng cong xuống bên phải
      ..cubicTo(
        centerX + curveHalfWidth * 0.42,
        baseTop - bumpHeight,
        centerX + curveHalfWidth * 0.56,
        baseTop,
        centerX + curveHalfWidth,
        baseTop,
      )
      // Đoạn thẳng tới góc trên phải bo tròn
      ..lineTo(size.width - cornerRadius, baseTop)
      ..quadraticBezierTo(size.width, baseTop, size.width, baseTop + cornerRadius)
      // Góc dưới phải bo tròn
      ..lineTo(size.width, size.height - cornerRadius)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width - cornerRadius,
        size.height,
      )
      // Góc dưới trái bo tròn
      ..lineTo(cornerRadius, size.height)
      ..quadraticBezierTo(0, size.height, 0, size.height - cornerRadius)
      ..close();

    // Đổ bóng mềm toàn bộ thanh dock nổi
    canvas.drawShadow(path, shadowColor, 14, false);

    // Tô nền trắng sạch
    final Paint fillPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Viền mảnh sắc nét bao quanh toàn khối
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FloatingWaveNavPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.shadowColor != shadowColor;
}