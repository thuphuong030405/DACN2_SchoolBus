import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/authentication/presentation/providers/auth_providers.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/profile/presentation/pages/parent/change_password_page.dart';
import 'package:mobile_app/features/profile/presentation/pages/parent/edit_profile_page.dart';
import 'package:mobile_app/features/profile/presentation/pages/parent/help_contact_page.dart';
import 'package:mobile_app/features/profile/presentation/widgets/child_profile_card.dart';
import 'package:mobile_app/features/students/presentation/pages/parent/link_child_page.dart';

const _ink = Color(0xFF10224A);
const _muted = Color(0xFF52628A);
const _blue = Color(0xFF1D4ED8);
const _red = Color(0xFFC8382F);

const _tileTitle = TextStyle(
  color: _ink,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  fontFamily: 'Be Vietnam Pro',
);
const _tileSub = TextStyle(color: _muted, fontSize: 12, fontFamily: 'Be Vietnam Pro');

const _cardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
];

/// "0912345678" -> "09•• ••• 678"
String _maskPhone(String p) {
  final d = p.replaceAll(RegExp(r'\s'), '');
  if (d.length < 8) return d;
  return '${d.substring(0, 2)}•• ••• ${d.substring(d.length - 3)}';
}

/// Chữ cái đầu của tên gọi (từ cuối): "Nguyễn Thị Lan" -> "L"
String _initial(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  if (parts.isEmpty) return 'P';
  return String.fromCharCode(parts.last.runes.first).toUpperCase();
}

class ParentProfilePage extends ConsumerStatefulWidget {
  const ParentProfilePage({super.key});

  @override
  ConsumerState<ParentProfilePage> createState() => _ParentProfilePageState();
}

class _ParentProfilePageState extends ConsumerState<ParentProfilePage> {
  // Giá trị tạm trong lúc đang lưu thông báo đẩy (null = lấy theo dữ liệu từ DB)
  bool? _pushOverride;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  // ---------------------------------------------------------- Thông báo đẩy
  Future<void> _setPush(bool value) async {
    setState(() => _pushOverride = value);
    try {
      await ref.read(parentRepositoryProvider).setNotificationsEnabled(value);
      ref.invalidate(childrenProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _pushOverride = null);
      _snack('Không lưu được cài đặt: $e');
    }
  }

  // ------------------------------------------------- Âm báo cảnh báo khẩn
  Future<void> _setEmergencySound(bool value) async {
    if (!value) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tắt âm báo cảnh báo khẩn?'),
          content: const Text(
            'Khi con bị bỏ quên trên xe, cảnh báo vẫn hiển thị trên màn hình '
            'nhưng sẽ không phát âm báo. Bạn chắc chắn muốn tắt?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Giữ bật')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Tắt âm báo')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await ref.read(emergencySoundProvider.notifier).set(value);
  }

  // ----------------------------------------------------------------- Ngôn ngữ
  void _showLanguage() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Tiếng Việt'),
              trailing: Icon(Icons.check, color: _blue),
            ),
            ListTile(
              enabled: false,
              title: Text('English'),
              subtitle: Text('Sắp có'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Đăng xuất
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục theo dõi con.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất')),
        ],
      ),
    );
    if (ok != true) return;

    // Xóa trạng thái của phiên cũ để tài khoản đăng nhập sau không thấy dữ liệu cũ
    ref.invalidate(selectedChildIdProvider);
    ref.invalidate(parentTabProvider);
    ref.invalidate(childrenProvider);
    ref.invalidate(myProfileProvider);
    await ref.read(logoutUseCaseProvider).call();
    ref.invalidate(currentUserProvider);
  }

  Future<void> _refresh() async {
    ref.invalidate(myProfileProvider);
    ref.invalidate(childrenProvider);
    final kids = ref.read(childrenProvider).asData?.value ?? const <ChildInfo>[];
    for (final c in kids) {
      ref.invalidate(childProfileInfoProvider(c.studentId));
      ref.invalidate(faceConsentProvider(c.studentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final childrenAsync = ref.watch(childrenProvider);
    final soundAsync = ref.watch(emergencySoundProvider);

    // Khi danh sách con tải xong -> bỏ giá trị tạm, dùng giá trị thật từ DB
    ref.listen<AsyncValue<List<ChildInfo>>>(childrenProvider, (prev, next) {
      if (next is AsyncData && mounted && _pushOverride != null) {
        setState(() => _pushOverride = null);
      }
    });

    final children = childrenAsync.asData?.value ?? const <ChildInfo>[];
    final approved = children.where((c) => c.isApproved).toList();
    final hasChildren = children.isNotEmpty;
    final pushFromDb = approved.isEmpty ? true : approved.every((c) => c.notificationsEnabled);
    final pushValue = _pushOverride ?? pushFromDb;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Header xanh đậm
            Container(
              padding: const EdgeInsets.only(top: 54, left: 20, right: 20, bottom: 24),
              decoration: const BoxDecoration(
                color: _blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hồ sơ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontFamily: 'Be Vietnam Pro',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // ---------------- Thẻ thông tin phụ huynh
                  profileAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => _ErrorRetry(
                      message: 'Lỗi tải thông tin: $e',
                      onRetry: () => ref.invalidate(myProfileProvider),
                    ),
                    data: (p) => Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _cardShadow,
                      ),
                      child: Row(
                        children: [
                     CircleAvatar(
                        radius: 24,
                        // backgroundColor: const Color(0xFFFFC93C),
                        backgroundImage: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                            ? NetworkImage(p.avatarUrl!) as ImageProvider
                            : null,
                        child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                            ? Text(
                                _initial(p.fullName),
                                style: const TextStyle(
                                  color: _ink,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              )
                            : null,
                      ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Be Vietnam Pro',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Phụ huynh • ${(p.phone != null && p.phone!.isNotEmpty) ? _maskPhone(p.phone!) : p.email}',
                                  style: _tileSub,
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _push(EditProfilePage(profile: p)),
                            child: const Text(
                              'Sửa',
                              style: TextStyle(
                                color: _blue,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---------------- Danh sách con + trạng thái khuôn mặt
                  childrenAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => _ErrorRetry(
                      message: 'Lỗi tải danh sách con: $e',
                      onRetry: () => ref.invalidate(childrenProvider),
                    ),
                    data: (all) => Column(
                      children: [
                        if (all.isEmpty)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _cardShadow,
                            ),
                            child: const Text(
                              'Bạn chưa liên kết với học sinh nào. Nhập mã học sinh '
                              'do nhà trường cấp để bắt đầu theo dõi con.',
                              style: _tileSub,
                            ),
                          ),
                        for (final c in all) ChildProfileCard(child: c),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _push(const LinkChildPage()),
                            icon: const Icon(Icons.person_add_alt_1, color: _blue),
                            label: const Text(
                              'Liên kết thêm con',
                              style: TextStyle(color: _blue, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---------------- Cài đặt chung
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _cardShadow,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications_none, color: _blue),
                            title: const Text('Thông báo đẩy', style: _tileTitle),
                            subtitle: Text(
                              hasChildren
                                  ? 'Lên/xuống xe, xe sắp tới. Cảnh báo khẩn luôn được gửi.'
                                  : 'Liên kết với con để bật thông báo',
                              style: _tileSub,
                            ),
                            value: pushValue,
                            activeTrackColor: _blue,
                            onChanged: hasChildren ? _setPush : null,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          SwitchListTile(
                            secondary: const Icon(Icons.notifications_active_outlined, color: _blue),
                            title: const Text('Âm báo cảnh báo khẩn', style: _tileTitle),
                            subtitle: const Text(
                              'Phát âm báo khi con có nguy cơ bị bỏ quên (trên máy này)',
                              style: _tileSub,
                            ),
                            value: soundAsync.asData?.value ?? true,
                            activeTrackColor: _blue,
                            onChanged: soundAsync.isLoading ? null : _setEmergencySound,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: const Icon(Icons.language, color: _blue),
                            title: const Text('Ngôn ngữ', style: _tileTitle),
                            trailing: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Tiếng Việt',
                                    style: TextStyle(color: _muted, fontSize: 13)),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                              ],
                            ),
                            onTap: _showLanguage,
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: const Icon(Icons.lock_outline, color: _blue),
                            title: const Text('Đổi mật khẩu', style: _tileTitle),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                            onTap: () => _push(const ChangePasswordPage()),
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: const Icon(Icons.help_outline, color: _blue),
                            title: const Text('Trợ giúp & liên hệ nhà trường', style: _tileTitle),
                            trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                            onTap: () => _push(const HelpContactPage()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------------- Đăng xuất
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red, width: 1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                      onPressed: _logout,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: _red, fontSize: 13)),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      );
}
