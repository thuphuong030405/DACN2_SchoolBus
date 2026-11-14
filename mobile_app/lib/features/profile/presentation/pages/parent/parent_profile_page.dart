import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/authentication/presentation/providers/auth_providers.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/profile/presentation/pages/parent/change_password_page.dart';
import 'package:mobile_app/features/profile/presentation/pages/parent/edit_profile_page.dart';
import 'package:mobile_app/features/profile/presentation/pages/parent/help_contact_page.dart';
import 'package:mobile_app/features/profile/presentation/widgets/child_profile_card.dart';
import 'package:mobile_app/features/students/presentation/pages/parent/register_child_page.dart';

const _bg = Color(0xFFEEF5FF);
const _primary = Color(0xFF102A63);
const _primaryMid = Color(0xFF1D4ED8);
const _primaryLight = Color(0xFF3B82F6);
const _ink = Color(0xFF10224A);
const _muted = Color(0xFF52628A);
const _blueSoft = Color(0xFFE0ECFF);
const _red = Color(0xFFC8382F);
const _redSoft = Color(0xFFFDE4E1);

const _tileTitle = TextStyle(
  color: _ink,
  fontSize: 14,
  fontWeight: FontWeight.w600,
  fontFamily: 'Be Vietnam Pro',
);
const _tileSub = TextStyle(
  color: _muted,
  fontSize: 12,
  fontFamily: 'Be Vietnam Pro',
);

const _cardShadow = [
  BoxShadow(color: Color(0x0A10224A), blurRadius: 10, offset: Offset(0, 3)),
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

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

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
              child: const Text('Giữ bật'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tắt âm báo'),
            ),
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
              trailing: Icon(Icons.check, color: _primaryMid),
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
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
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
    final topPadding = MediaQuery.of(context).padding.top;

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
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // 1. Header Gradient đồng bộ
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryMid, _primaryLight],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -45,
                    top: -45,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: const BoxDecoration(
                        color: Color(0x14FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    left: -35,
                    bottom: -25,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Color(0x10FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 22),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0x26FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hồ sơ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontFamily: 'Be Vietnam Pro',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Quản lý tài khoản, thông tin bé và cài đặt',
                                style: TextStyle(
                                  color: Color(0xFFDBE8FF),
                                  fontSize: 12.5,
                                  fontFamily: 'Be Vietnam Pro',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Nội dung chính
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: _cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [_primaryMid, _primaryLight],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: _blueSoft,
                              backgroundImage: (p.avatarUrl != null && p.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(p.avatarUrl!) as ImageProvider
                                  : null,
                              child: (p.avatarUrl == null || p.avatarUrl!.isEmpty)
                                  ? Text(
                                      _initial(p.fullName),
                                      style: const TextStyle(
                                        color: _primaryMid,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                        fontFamily: 'Be Vietnam Pro',
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.fullName,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Be Vietnam Pro',
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Phụ huynh · ${(p.phone != null && p.phone!.isNotEmpty) ? _maskPhone(p.phone!) : p.email}',
                                  style: _tileSub,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: () => _push(EditProfilePage(profile: p)),
                            style: FilledButton.styleFrom(
                              backgroundColor: _blueSoft,
                              foregroundColor: _primaryMid,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: const Text(
                              'Sửa',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Be Vietnam Pro',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---------------- Danh sách con + trạng thái khuôn mặt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Học sinh liên kết',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Be Vietnam Pro',
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _push(const RegisterChildPage()),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.person_add_alt_1_rounded,
                            size: 17, color: _primaryMid),
                        label: const Text(
                          'Đăng ký thêm con',
                          style: TextStyle(
                            color: _primaryMid,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Be Vietnam Pro',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
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
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: _cardShadow,
                            ),
                            child: const Text(
                              'Bạn chưa liên kết với học sinh nào. Nhập mã học sinh '
                              'do nhà trường cấp để bắt đầu theo dõi con.',
                              style: _tileSub,
                            ),
                          ),
                        for (final c in all) ChildProfileCard(child: c),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---------------- Cài đặt chung
                  const Text(
                    'Cài đặt & Hỗ trợ',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Be Vietnam Pro',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: _cardShadow,
                    ),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          SwitchListTile(
                            secondary: _iconBox(Icons.notifications_none_rounded),
                            title: const Text('Thông báo đẩy', style: _tileTitle),
                            subtitle: Text(
                              hasChildren
                                  ? 'Lên/xuống xe, xe sắp tới. Cảnh báo khẩn luôn được gửi.'
                                  : 'Đăng ký con để bật thông báo',
                              style: _tileSub,
                            ),
                            value: pushValue,
                            activeTrackColor: _primaryMid,
                            onChanged: hasChildren ? _setPush : null,
                          ),
                          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                          SwitchListTile(
                            secondary: _iconBox(Icons.notifications_active_outlined),
                            title: const Text('Âm báo cảnh báo khẩn', style: _tileTitle),
                            subtitle: const Text(
                              'Phát âm báo khi con có nguy cơ bị bỏ quên (trên máy này)',
                              style: _tileSub,
                            ),
                            value: soundAsync.asData?.value ?? true,
                            activeTrackColor: _primaryMid,
                            onChanged: soundAsync.isLoading ? null : _setEmergencySound,
                          ),
                          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: _iconBox(Icons.language_rounded),
                            title: const Text('Ngôn ngữ', style: _tileTitle),
                            trailing: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Tiếng Việt',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 13,
                                    fontFamily: 'Be Vietnam Pro',
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                              ],
                            ),
                            onTap: _showLanguage,
                          ),
                          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: _iconBox(Icons.lock_outline_rounded),
                            title: const Text('Đổi mật khẩu', style: _tileTitle),
                            trailing:
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                            onTap: () => _push(const ChangePasswordPage()),
                          ),
                          const Divider(height: 1, indent: 64, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: _iconBox(Icons.help_outline_rounded),
                            title: const Text('Trợ giúp & liên hệ nhà trường', style: _tileTitle),
                            trailing:
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                            onTap: () => _push(const HelpContactPage()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ---------------- Nút Đăng xuất
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _red,
                        side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 20),
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

                  // Khoảng đệm đáy đủ lớn để không bị thanh BottomNavigationBar che khuất
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _blueSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _primaryMid, size: 20),
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
          borderRadius: BorderRadius.circular(18),
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