import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/students/presentation/pages/parent/child_profile_page.dart';
import 'package:mobile_app/features/students/presentation/providers/student_providers.dart';
import 'package:mobile_app/features/students/presentation/widgets/face_state_style.dart';

const _ink = Color(0xFF10224A);
const _muted = Color(0xFF52628A);
const _blue = Color(0xFF1D4ED8);

const _relationLabels = {
  'FATHER': 'Bố',
  'MOTHER': 'Mẹ',
  'GUARDIAN': 'Người giám hộ',
  'OTHER': 'Khác',
};

/// "Bé Minh Anh" -> "MA" (an toàn với tên rỗng / 1 chữ)
String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  String first(String s) => String.fromCharCode(s.runes.first).toUpperCase();
  if (parts.length == 1) return first(parts.first);
  return first(parts[parts.length - 2]) + first(parts.last);
}

/// Ảnh đại diện của con; nếu chưa có ảnh hoặc ảnh không tải được thì hiện chữ cái đầu tên.
class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({required this.url, required this.name, required this.radius});
  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: _blue,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.65,
          fontFamily: 'Be Vietnam Pro',
        ),
      ),
    );
    final u = url;
    if (u == null || u.isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        u,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class ChildProfileCard extends ConsumerWidget {
  const ChildProfileCard({super.key, required this.child});
  final ChildInfo child;

  static const _shadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _shadow,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: child.isApproved
            ? _Approved(child: child)
            : _NotApproved(child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------- Đã duyệt

class _Approved extends ConsumerWidget {
  const _Approved({required this.child});
  final ChildInfo child;

  String _subtitle(ChildInfo c, ChildProfileInfo? i) {
    final parts = <String>[];
    final cls = c.className;
    if (cls != null && cls.isNotEmpty) parts.add('Lớp $cls');
    final route = i?.routeName;
    if (route != null) parts.add(route);
    final pickup = i?.pickupAddress ?? i?.pickupStopName;
    if (pickup != null) parts.add('Điểm đón: $pickup');
    if (i != null && route == null) parts.add('Chưa được xếp tuyến xe');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(childProfileInfoProvider(child.studentId));
    final faceAsync = ref.watch(childFaceStatusProvider(child.studentId));

    final loading = infoAsync.isLoading || faceAsync.isLoading;
    final failed = infoAsync.hasError || faceAsync.hasError;
    final status = faceAsync.asData?.value;
    final state = faceStateOf(status);
    final style = faceStateStyle(state, samples: status?.sampleCount ?? 0);

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChildProfilePage(child: child)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ChildAvatar(url: child.avatarUrl, name: child.fullName, radius: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.fullName,
                          style: const TextStyle(
                              color: _ink,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Be Vietnam Pro')),
                      const SizedBox(height: 2),
                      Text(
                        loading
                            ? 'Đang tải thông tin...'
                            : _subtitle(child, infoAsync.asData?.value),
                        style: const TextStyle(
                            color: _muted, fontSize: 12, fontFamily: 'Be Vietnam Pro'),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const SizedBox(
                height: 28,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              )
            else if (failed)
              InkWell(
                onTap: () {
                  ref.invalidate(childProfileInfoProvider(child.studentId));
                  ref.invalidate(childFaceStatusProvider(child.studentId));
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('Không tải được trạng thái khuôn mặt · Bấm để thử lại',
                      style: TextStyle(color: Color(0xFFC8382F), fontSize: 12)),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(style.icon, size: 14, color: style.fg),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(style.chip,
                          style: TextStyle(
                              color: style.fg,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Be Vietnam Pro')),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Text(
              'Chỉ lưu vector khuôn mặt đã mã hóa, không lưu ảnh gốc. '
              'Bạn có thể thu hồi đồng ý bất cứ lúc nào.',
              style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 11,
                  fontFamily: 'Be Vietnam Pro',
                  height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------ Chờ duyệt / bị từ chối

class _NotApproved extends ConsumerWidget {
  const _NotApproved({required this.child});
  final ChildInfo child;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final rejected = child.verificationStatus == 'REJECTED';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(rejected ? 'Xóa yêu cầu?' : 'Hủy yêu cầu liên kết?'),
        content: Text(rejected
            ? 'Yêu cầu bị từ chối sẽ được xóa. Bạn có thể gửi lại bằng mã học sinh.'
            : 'Yêu cầu đang chờ nhà trường duyệt sẽ bị hủy.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(rejected ? 'Xóa' : 'Hủy yêu cầu')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(parentRepositoryProvider).cancelLinkRequest(child.studentId);
      ref.invalidate(childrenProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Không thực hiện được: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejected = child.verificationStatus == 'REJECTED';
    final rel = _relationLabels[child.relationship] ?? child.relationship;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: rejected ? const Color(0xFFFCE4E1) : const Color(0xFFFEF3C7),
                child: Icon(
                  rejected ? Icons.close : Icons.hourglass_top,
                  color: rejected ? const Color(0xFF9B2C22) : const Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rejected ? 'Yêu cầu liên kết bị từ chối' : 'Đang chờ nhà trường duyệt',
                      style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Be Vietnam Pro'),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rejected
                          ? 'Bạn có thể xóa yêu cầu rồi gửi lại bằng mã học sinh.'
                          : 'Yêu cầu liên kết với tư cách: $rel',
                      style: const TextStyle(
                          color: _muted, fontSize: 12, fontFamily: 'Be Vietnam Pro'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _cancel(context, ref),
              child: Text(rejected ? 'Xóa yêu cầu' : 'Hủy yêu cầu'),
            ),
          ),
        ],
      ),
    );
  }
}