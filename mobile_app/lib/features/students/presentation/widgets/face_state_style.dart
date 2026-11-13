import 'package:flutter/material.dart';
import 'package:mobile_app/features/students/data/models/student_model.dart';

/// 4 trạng thái khuôn mặt của con (PHỤ HUYNH là người đồng ý và đăng ký ảnh).
enum FaceState {
  notConsented, // chưa đồng ý
  revoked, //      đã thu hồi đồng ý (vector đã bị xóa)
  needFace, //     đã đồng ý nhưng chưa đăng ký ảnh
  ready, //        đã đồng ý + đã đăng ký -> điểm danh tự động
}

FaceState faceStateOf(FaceStatus? s) {
  if (s == null) return FaceState.notConsented;
  if (s.consentStatus == 'GRANTED') return s.hasFace ? FaceState.ready : FaceState.needFace;
  if (s.consentStatus == 'REVOKED') return FaceState.revoked;
  return FaceState.notConsented;
}

class FaceStateStyle {
  const FaceStateStyle({
    required this.chip,
    required this.detail,
    required this.bg,
    required this.fg,
    required this.icon,
  });
  final String chip;
  final String detail;
  final Color bg;
  final Color fg;
  final IconData icon;
}

FaceStateStyle faceStateStyle(FaceState s, {int samples = 0}) {
  switch (s) {
    case FaceState.ready:
      return FaceStateStyle(
        chip: 'Đã đăng ký khuôn mặt',
        detail: 'Đã đăng ký $samples ảnh mẫu. Xe sẽ điểm danh tự động khi con lên/xuống xe.',
        bg: const Color(0xFFDCF1E3),
        fg: const Color(0xFF1E6B3A),
        icon: Icons.verified_user,
      );
    case FaceState.needFace:
      return const FaceStateStyle(
        chip: 'Đã đồng ý · chưa đăng ký ảnh',
        detail: 'Bạn đã đồng ý. Hãy chụp ảnh khuôn mặt của con để xe điểm danh tự động. '
            'Khi chưa đăng ký, cô giáo điểm danh thủ công.',
        bg: Color(0xFFE0ECFF),
        fg: Color(0xFF1D4ED8),
        icon: Icons.add_a_photo_outlined,
      );
    case FaceState.revoked:
      return const FaceStateStyle(
        chip: 'Đã thu hồi đồng ý',
        detail: 'Dữ liệu khuôn mặt của con đã bị xóa. Việc điểm danh được làm thủ công. '
            'Bạn có thể đồng ý và đăng ký lại bất cứ lúc nào.',
        bg: Color(0xFFFCE4E1),
        fg: Color(0xFF9B2C22),
        icon: Icons.gpp_bad_outlined,
      );
    case FaceState.notConsented:
      return const FaceStateStyle(
        chip: 'Chưa đăng ký khuôn mặt',
        detail: 'Đăng ký khuôn mặt để xe điểm danh tự động. Cần bạn đồng ý trước. '
            'Khi chưa đăng ký, cô giáo điểm danh thủ công.',
        bg: Color(0xFFFEF3C7),
        fg: Color(0xFFD97706),
        icon: Icons.gpp_maybe_outlined,
      );
  }
}