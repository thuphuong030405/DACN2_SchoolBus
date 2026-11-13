import 'package:flutter/material.dart';

/// Màu và kiểu chữ dùng cho giao diện lộ trình (theo thiết kế Figma).
class RoutePalette {
  const RoutePalette._();

  static const Color navy = Color(0xFF10224A);
  static const Color grey = Color(0xFF52628A);
  static const Color blue = Color(0xFF2563EB);
  static const Color blueDark = Color(0xFF1D4ED8);
  static const Color blueLight = Color(0xFFE0ECFF);
  static const Color amber = Color(0xFFFFC93C);
  static const Color amberLight = Color(0xFFFFF7DB);
  static const Color green = Color(0xFF16A34A);
  static const Color greenLight = Color(0xFFDCF1E3);
  static const Color greenDark = Color(0xFF1E6B3A);
  static const Color red = Color(0xFFC8382F);
  static const Color outline = Color(0xFFB3C2E0);

  /// Font của thiết kế. Nếu chưa thêm font này vào app thì Flutter tự dùng font mặc định.
  static const String fontFamily = 'Be Vietnam Pro';

  static TextStyle text(
    double size,
    FontWeight weight,
    Color color, {
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      shadows: shadows,
    );
  }
}