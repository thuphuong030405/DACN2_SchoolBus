import 'package:flutter/material.dart';

/// Bảng màu của giao diện phụ huynh (lấy từ Figma).
class HomeColors {
  HomeColors._();

  static const bg = Color(0xFFEEF5FF);
  static const primary = Color(0xFF1D4ED8);
  static const primaryMid = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF3B82F6);
  static const ink = Color(0xFF10224A);
  static const muted = Color(0xFF52628A);
  static const border = Color(0xFFDDE6F5);
  static const blueSoft = Color(0xFFE0ECFF);
  static const yellow = Color(0xFFFFC93C);
  static const yellowSoft = Color(0xFFFFF0BD);
  static const yellowText = Color(0xFF7A4A00);
  static const greenSoft = Color(0xFFDCF1E3);
  static const greenText = Color(0xFF1E6B3A);
  static const green = Color(0xFF16A34A);
  static const red = Color(0xFFC8382F);
  static const redSoft = Color(0xFFFDE4E1);
  static const redText = Color(0xFF9B2C22);
  static const greySoft = Color(0xFFE3EAF7);
  static const grey = Color(0xFFB3C2E0);
}

/// Kiểu chữ chung (font Be Vietnam Pro; chưa khai báo font thì Flutter dùng font mặc định).
TextStyle homeText(double size, FontWeight weight, Color color, {double? height}) =>
    TextStyle(
      fontFamily: 'Be Vietnam Pro',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );