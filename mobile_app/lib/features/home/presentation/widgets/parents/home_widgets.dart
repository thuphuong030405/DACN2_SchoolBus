import 'package:flutter/material.dart';
import 'package:mobile_app/features/home/presentation/pages/parent/home_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
/// Thẻ trắng bo góc có bóng nhẹ.
class HomeCard extends StatelessWidget {
  const HomeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
  });
  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x1F10224A), blurRadius: 14, offset: Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

class HomeSectionTitle extends StatelessWidget {
  const HomeSectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: HomeColors.primaryMid,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: homeText(15, FontWeight.w700, HomeColors.ink)),
        ],
      ),
    );
  }
}

/// Tên bucket Storage chứa ảnh học sinh. CHỈ dùng khi cột students.avatar_url lưu ĐƯỜNG DẪN
/// (vd "students/abc.jpg") thay vì link đầy đủ (https://...).
const kAvatarBucket = 'avatars'; // TODO: đổi đúng tên bucket của nhóm

/// Link ảnh dùng được: giữ nguyên nếu đã là http(s), nếu là đường dẫn thì đổi sang link công khai.
String? resolveAvatarUrl(String? raw) {
  final v = raw?.trim() ?? '';
  if (v.isEmpty) return null;
  if (v.startsWith('http://') || v.startsWith('https://')) return v;
  try {
    return Supabase.instance.client.storage.from(kAvatarBucket).getPublicUrl(v);
  } catch (_) {
    return null;
  }
}

/// Ảnh tròn của học sinh; chưa có ảnh (hoặc tải lỗi) thì hiện chữ viết tắt trên nền gradient.
class HomeAvatar extends StatelessWidget {
  const HomeAvatar({super.key, required this.text, this.imageUrl, this.size = 44});
  final String text;
  final String? imageUrl;
  final double size;

  Widget _initials() => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [HomeColors.primaryMid, HomeColors.primaryLight],
          ),
        ),
        child: Text(text, style: homeText(size * 0.34, FontWeight.w700, Colors.white)),
      );

  @override
  Widget build(BuildContext context) {
    final url = resolveAvatarUrl(imageUrl);
    if (url == null) return _initials();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initials(),
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _initials(),
        ),
      ),
    );
  }
}

class HomeStatusChip extends StatelessWidget {
  const HomeStatusChip({super.key, required this.text, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: homeText(13, FontWeight.w600, fg)),
    );
  }
}

/// Nút chọn dạng viên thuốc trên nền gradient (chọn con, chọn chuyến).
class HomePill extends StatelessWidget {
  const HomePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? HomeColors.primary : Colors.white;
    return Material(
      color: selected ? Colors.white : const Color(0x26FFFFFF),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: fg), const SizedBox(width: 6)],
              Text(label, style: homeText(13, FontWeight.w600, fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vòng tròn trang trí mờ ở nền banner.
class HomeCircle extends StatelessWidget {
  const HomeCircle({super.key, required this.size, required this.alpha});
  final double size;
  final int alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.fromARGB(alpha, 255, 255, 255),
      ),
    );
  }
}

/// Khung thông báo màu (cảnh báo, nghỉ học), có thể kèm nút gọi.
class HomeBanner extends StatelessWidget {
  const HomeBanner({
    super.key,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color bg;
  final Color fg;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: homeText(13, FontWeight.w600, fg, height: 1.4)),
                if (actionLabel != null && onAction != null)
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: fg,
                      padding: const EdgeInsets.only(top: 6),
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onAction,
                    icon: const Icon(Icons.call, size: 16),
                    label: Text(actionLabel!, style: homeText(13, FontWeight.w700, fg)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}