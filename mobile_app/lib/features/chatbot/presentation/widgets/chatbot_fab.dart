import 'package:flutter/material.dart';

import 'package:mobile_app/features/chatbot/presentation/pages/chatbot_page.dart';

/// Nút chatbot nổi ở góc phải dưới màn hình. Bấm để mở trợ lý AI,
/// giữ và kéo để di chuyển sang chỗ khác nếu nó che nội dung.
///
/// Widget này trả về `Positioned`, nên PHẢI đặt trực tiếp trong một `Stack`
/// (xem auth_gate.dart: nút được gắn cho mọi vai trò sau khi đăng nhập).
class ChatbotFab extends StatefulWidget {
  /// Vai trò hiển thị cho AI biết (vd: 'phụ huynh', 'giáo viên', 'tài xế').
  final String? userRole;

  /// Vị trí ban đầu: khoảng cách từ mép dưới / mép phải.
  /// Mặc định 110 để nằm phía trên thanh điều hướng.
  final double bottom;
  final double right;

  const ChatbotFab({
    super.key,
    this.userRole,
    this.bottom = 110,
    this.right = 16,
  });

  @override
  State<ChatbotFab> createState() => _ChatbotFabState();
}

class _ChatbotFabState extends State<ChatbotFab> {
  static const double _size = 56;
  static const double _margin = 8;

  late double _right = widget.right;
  late double _bottom = widget.bottom;

  void _onDrag(DragUpdateDetails d, Size screen, EdgeInsets padding) {
    setState(() {
      _right = (_right - d.delta.dx)
          .clamp(_margin, screen.width - _size - _margin)
          .toDouble();
      _bottom = (_bottom - d.delta.dy)
          .clamp(_margin, screen.height - padding.top - _size - _margin)
          .toDouble();
    });
  }

  void _open() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatbotPage(userRole: widget.userRole),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Positioned(
      right: _right,
      bottom: _bottom,
      child: Tooltip(
        message: 'Trợ lý AI',
        child: GestureDetector(
          onTap: _open,
          onPanUpdate: (d) => _onDrag(d, media.size, media.padding),
          child: Container(
            width: _size,
            height: _size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x662563EB),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}