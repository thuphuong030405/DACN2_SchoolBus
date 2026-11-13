import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/authentication/domain/entities/app_user.dart';
import 'package:mobile_app/features/authentication/presentation/providers/auth_providers.dart';
import 'package:mobile_app/features/authentication/presentation/pages/auth_gate.dart';
import 'package:mobile_app/features/profile/domain/entities/teacher_work_info.dart';
import 'package:mobile_app/features/profile/domain/profile_exception.dart';
import 'package:mobile_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:mobile_app/features/profile/presentation/providers/teacher_work_info_provider.dart';
import 'package:mobile_app/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:mobile_app/features/profile/presentation/widgets/edit_profile_sheet.dart';
import 'package:mobile_app/features/trips/presentation/pages/teacher/teacher_trip_history_page.dart';

enum _AvatarAction { camera, gallery, remove }

// =========================================================
// MÀU SẮC & KIỂU CHỮ THEO THIẾT KẾ FIGMA
// =========================================================

class _C {
  const _C._();

  static const Color background = Color(0xFFEEF5FF);
  static const Color header = Color(0xFF1D4ED8);
  static const Color navy = Color(0xFF10224A);
  static const Color grey = Color(0xFF52628A);
  static const Color blue = Color(0xFF2563EB);
  static const Color avatarYellow = Color(0xFFFFC93C);
  static const Color amberBadge = Color(0xFFFFF0BD);
  static const Color amberText = Color(0xFF7A4A00);
  static const Color codeBadge = Color(0xFFE8EDF7);
  static const Color codeText = Color(0xFF3A4D75);
  static const Color greenBadge = Color(0xFFDCF1E3);
  static const Color greenText = Color(0xFF1E6B3A);
  static const Color redBadge = Color(0xFFFBE0DD);
  static const Color redText = Color(0xFF9B2C22);
  static const Color divider = Color(0xFFE3EAF7);
  static const Color logout = Color(0xFF9B2C22);
  static const Color switchOff = Color(0xFF8FA2A1);
  static const Color cardShadow = Color(0x1E10224A);

  /// Font của thiết kế. Nếu app chưa có font này thì Flutter tự dùng font mặc định.
  static const String font = 'Be Vietnam Pro';
}

TextStyle _text(double size, FontWeight weight, Color color) {
  return TextStyle(
    fontFamily: _C.font,
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

class TeacherProfilePage extends ConsumerStatefulWidget {
  final AppUser user;

  const TeacherProfilePage({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<TeacherProfilePage> createState() =>
      _TeacherProfilePageState();
}

class _TeacherProfilePageState extends ConsumerState<TeacherProfilePage> {
  static const double _avatarSize = 60;
  static const String _roleLabel = 'Bảo mẫu';

  /// Hiển thị khi chưa có dữ liệu.
  static const String _empty = '—';

  final ImagePicker _picker = ImagePicker();

  bool isLoggingOut = false;
  bool _isUploadingAvatar = false;

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    // Lấy sẵn MỌI thứ cần dùng TRƯỚC khi await.
    // Sau signOut(), AuthGate rebuild và trang này bị dispose,
    // nên sau đó không được dùng context / ref / setState của State này nữa.
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);

    try {
      // 1. Đăng xuất khỏi Supabase (xóa session)
      await Supabase.instance.client.auth.signOut();

      debugPrint(
        'LOGOUT OK -> session = ${Supabase.instance.client.auth.currentSession}',
      );

      // 2. Làm mới thông tin user bằng container (an toàn dù widget đã dispose)
      container.invalidate(currentUserProvider);
      container.invalidate(teacherWorkInfoProvider);

      // 3. Thay toàn bộ stack bằng AuthGate mới -> hiện LoginPage.
      //    Không gọi setState ở đây vì trang này sắp bị gỡ bỏ.
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Đăng xuất thất bại: $error'),
          backgroundColor: Colors.red,
        ),
      );

      // Chỉ trong nhánh lỗi (trang vẫn còn) mới setState, và phải kiểm tra mounted
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Đăng xuất'),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: isLoggingOut
                  ? null
                  : () {
                      Navigator.pop(dialogContext);
                      logout();
                    },
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // CHỈNH SỬA TÊN / EMAIL
  // =====================================================

  Future<void> _openEditProfile({
    required String name,
    required String email,
  }) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditProfileSheet(
        initialName: name,
        initialEmail: email,
      ),
    );

    if (message == null || !mounted) return;

    _refreshProfile();
    _showSnack(message);
  }

  // =====================================================
  // ĐỔI MẬT KHẨU
  // =====================================================

  Future<void> _openChangePassword() async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ChangePasswordSheet(),
    );

    if (message == null || !mounted) return;

    _showSnack(message);
  }

  // =====================================================
  // LỊCH SỬ ĐƯA ĐÓN
  // =====================================================

  void _openTripHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeacherTripHistoryPage()),
    );
  }

  // =====================================================
  // ẢNH ĐẠI DIỆN
  // =====================================================

  Future<void> _openAvatarOptions({required bool hasAvatar}) async {
    if (_isUploadingAvatar) return;

    final action = await showModalBottomSheet<_AvatarAction>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading:
                    const Icon(Icons.photo_camera_outlined, color: _C.blue),
                title: const Text('Chụp ảnh mới'),
                onTap: () => Navigator.pop(sheetContext, _AvatarAction.camera),
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library_outlined, color: _C.blue),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.pop(sheetContext, _AvatarAction.gallery),
              ),
              if (hasAvatar)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text(
                    'Xóa ảnh hiện tại',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _AvatarAction.remove),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action == null || !mounted) return;

    switch (action) {
      case _AvatarAction.camera:
        await _pickAndUploadAvatar(ImageSource.camera);
      case _AvatarAction.gallery:
        await _pickAndUploadAvatar(ImageSource.gallery);
      case _AvatarAction.remove:
        await _removeAvatar();
    }
  }

  String _contentTypeOf(XFile file) {
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      // Tự thu nhỏ ảnh để tải lên nhanh và nhẹ
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (file == null) return; // người dùng huỷ

      if (mounted) setState(() => _isUploadingAvatar = true);

      final bytes = await file.readAsBytes();

      await ref
          .read(profileRepositoryProvider)
          .uploadAvatar(bytes, _contentTypeOf(file));

      if (!mounted) return;

      _refreshProfile();
      _showSnack('Đã cập nhật ảnh đại diện.');
    } on ProfileException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (_) {
      if (mounted) {
        _showSnack(
          'Không thể mở camera hoặc thư viện ảnh. Hãy kiểm tra quyền truy cập.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _isUploadingAvatar = true);

    try {
      await ref.read(profileRepositoryProvider).removeAvatar();

      if (!mounted) return;

      _refreshProfile();
      _showSnack('Đã xóa ảnh đại diện.');
    } on ProfileException catch (e) {
      if (mounted) _showSnack(e.message, isError: true);
    } catch (_) {
      if (mounted) _showSnack('Không thể xóa ảnh đại diện.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  // =====================================================
  // TIỆN ÍCH
  // =====================================================

  /// Tải lại hồ sơ, thông tin tài khoản và thông tin công việc.
  void _refreshProfile() {
    ref.invalidate(userProfileProvider);
    ref.invalidate(teacherWorkInfoProvider);
    ref.invalidate(currentUserProvider);
  }

  Future<void> _onPullToRefresh() async {
    _refreshProfile();
    try {
      await ref.read(teacherWorkInfoProvider.future);
    } catch (_) {
      // Lỗi đã hiển thị ở thẻ đỏ trên màn hình, bỏ qua ở đây.
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature đang được phát triển.'),
      ),
    );
  }

  /// "Nguyễn Thị Hà" -> "NH"
  String _initials(String name) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (words.isEmpty) return '?';

    String first(String w) => String.fromCharCode(w.runes.first).toUpperCase();

    if (words.length == 1) return first(words.first);
    return first(words.first) + first(words.last);
  }

  // ---------- Định dạng dữ liệu công việc ----------

  String _formatOnTime(double? rate) =>
      rate == null ? _empty : '${(rate * 100).round()}%';

  String _formatVehicle(TeacherWorkInfo? info) {
    final plate = info?.licensePlate?.trim();
    final route = info?.routeName?.trim();

    final parts = <String>[
      if (plate != null && plate.isNotEmpty) plate,
      if (route != null && route.isNotEmpty) route,
    ];
    return parts.isEmpty ? _empty : parts.join(' · ');
  }

  String _formatDriver(TeacherWorkInfo? info) {
    final name = info?.driverName?.trim();
    return (name == null || name.isEmpty) ? _empty : name;
  }

  /// Trả về (chữ hiển thị, màu nền, màu chữ) cho hạn bằng lái của tài xế:
  /// xanh = còn hạn, vàng = sắp hết hạn (<= 30 ngày), đỏ = đã hết hạn, xám = chưa có.
  (String, Color, Color) _licenseBadge(DateTime? expiry) {
    if (expiry == null) {
      return ('Chưa cập nhật', _C.codeBadge, _C.codeText);
    }

    final dd = expiry.day.toString().padLeft(2, '0');
    final mm = expiry.month.toString().padLeft(2, '0');
    final label = '$dd/$mm/${expiry.year}';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(expiry.year, expiry.month, expiry.day);

    if (end.isBefore(today)) {
      return ('Hết hạn $label', _C.redBadge, _C.redText);
    }
    if (end.difference(today).inDays <= 30) {
      return ('Sắp hết hạn $label', _C.amberBadge, _C.amberText);
    }
    return ('Hạn $label', _C.greenBadge, _C.greenText);
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.hasValue ? profileAsync.value : null;

    final workAsync = ref.watch(teacherWorkInfoProvider);
    final work = workAsync.hasValue ? workAsync.value : null;
    final workLoading = workAsync.isLoading && !workAsync.hasValue;
    final workError = workAsync.hasError && !workAsync.hasValue;

    // Dữ liệu từ database nếu đã tải xong, nếu chưa thì dùng dữ liệu truyền vào
    final name = profile?.fullName ?? widget.user.fullName;
    final email = profile?.email ?? widget.user.email;
    final hasAvatar = profile?.hasAvatar ?? false;
    final avatarUrl = hasAvatar ? profile?.avatarUrl : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.background,
        body: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          edgeOffset: 80,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(context),

                // Nội dung đè lên phần header 40px
                Transform.translate(
                  offset: const Offset(0, -40),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildProfileCard(
                          name: name,
                          email: email,
                          avatarUrl: avatarUrl,
                          work: work,
                          loading: workLoading,
                        ),
                        const SizedBox(height: 12),
                        if (workError) ...[
                          _buildErrorCard(),
                          const SizedBox(height: 12),
                        ],
                        _buildInfoCard(work, loading: workLoading),
                        const SizedBox(height: 12),
                        _buildMenuCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // HEADER XANH
  // =====================================================

  Widget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    Widget circle(double size, double alpha) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: alpha),
          ),
        );

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(28),
        bottomRight: Radius.circular(28),
      ),
      child: Container(
        width: double.infinity,
        color: _C.header,
        child: Stack(
          children: [
            Positioned(right: -36, top: -48, child: circle(150, 0.08)),
            Positioned(right: 64, bottom: -56, child: circle(96, 0.06)),
            Padding(
              padding: EdgeInsets.fromLTRB(20, topPadding + 24, 20, 56),
              child: Text(
                'Hồ sơ',
                style: _text(24, FontWeight.w700, Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // THẺ HỒ SƠ: ẢNH + TÊN + SỐ LIỆU
  // =====================================================

  Widget _buildProfileCard({
    required String name,
    required String email,
    required String? avatarUrl,
    required TeacherWorkInfo? work,
    required bool loading,
  }) {
    final code = work?.teacherCode?.trim();

    // Đang tải -> "…", chưa có dữ liệu -> "—"
    String stat(String? value) => loading ? '…' : (value ?? _empty);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: _C.cardShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAvatar(name: name, avatarUrl: avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _text(18, FontWeight.w700, _C.navy),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(12, FontWeight.w400, _C.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildPill(_roleLabel, _C.amberBadge, _C.amberText),
                        if (code != null && code.isNotEmpty)
                          _buildPill(code, _C.codeBadge, _C.codeText),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chỉnh sửa thông tin',
                onPressed: () => _openEditProfile(name: name, email: email),
                icon: const Icon(Icons.edit_outlined, color: _C.blue, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  stat(work?.completedTrips.toString()),
                  'Chuyến',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStat(
                  stat(work?.reportedIncidents.toString()),
                  'Sự cố',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStat(
                  stat(work == null ? null : _formatOnTime(work.onTimeRate)),
                  'Đúng giờ',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar({
    required String name,
    required String? avatarUrl,
  }) {
    final hasAvatar = avatarUrl != null;

    final initials = Center(
      child: Text(
        _initials(name),
        textAlign: TextAlign.center,
        style: _text(22, FontWeight.w700, _C.navy),
      ),
    );

    return GestureDetector(
      onTap: () => _openAvatarOptions(hasAvatar: hasAvatar),
      child: SizedBox(
        width: _avatarSize,
        height: _avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: _avatarSize,
              height: _avatarSize,
              decoration: const BoxDecoration(
                color: _C.avatarYellow,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        avatarUrl,
                        width: _avatarSize,
                        height: _avatarSize,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => initials,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    : initials,
              ),
            ),

            // Lớp phủ khi đang tải ảnh lên
            if (_isUploadingAvatar)
              Container(
                width: _avatarSize,
                height: _avatarSize,
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Nút máy ảnh nhỏ ở góc
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _C.blue, width: 1.5),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  size: 12,
                  color: _C.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: _text(12, FontWeight.w600, foreground),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: _C.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: _text(19, FontWeight.w700, _C.navy),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: _text(11, FontWeight.w400, _C.grey),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // THẺ LỖI TẢI DỮ LIỆU CÔNG VIỆC
  // =====================================================

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.redBadge,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _C.redText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Không tải được thông tin công việc.',
              style: _text(13, FontWeight.w500, _C.redText),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(teacherWorkInfoProvider),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // THẺ THÔNG TIN CÔNG VIỆC
  // =====================================================

  Widget _buildInfoCard(TeacherWorkInfo? work, {required bool loading}) {
    Widget valueText(String text) => Text(
          loading ? '…' : text,
          textAlign: TextAlign.right,
          style: _text(14, FontWeight.w700, _C.navy),
        );

    final license = _licenseBadge(work?.driverLicenseExpiry);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            label: 'Xe phụ trách',
            value: valueText(_formatVehicle(work)),
          ),
          _buildInfoRow(
            label: 'Tài xế đi cùng',
            value: valueText(_formatDriver(work)),
          ),
          _buildInfoRow(
            label: 'Bằng lái tài xế',
            showDivider: false,
            value: loading
                ? valueText('')
                : (work == null
                    ? valueText(_empty)
                    : _buildPill(license.$1, license.$2, license.$3)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required Widget value,
    bool showDivider = true,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 43),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: _C.divider, width: 1))
            : null,
      ),
      child: Row(
        children: [
          Text(label, style: _text(14, FontWeight.w400, _C.grey)),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: value,
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // THẺ MENU
  // =====================================================

  Widget _buildMenuCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildMenuRow(
                icon: Icons.history,
                label: 'Lịch sử đưa đón',
                onTap: _openTripHistory,
              ),
              _buildMenuRow(
                icon: Icons.report_gmailerrorred_outlined,
                label: 'Báo cáo sự cố đã gửi',
                onTap: () => _showComingSoon('Báo cáo sự cố đã gửi'),
              ),
              _buildMenuRow(
                icon: Icons.lock_outline,
                label: 'Đổi mật khẩu',
                onTap: _openChangePassword,
              ),
              _buildMenuRow(
                icon: Icons.dark_mode_outlined,
                label: 'Chế độ tối',
                onTap: () => _showComingSoon('Chế độ tối'),
                trailing: _buildSwitchPreview(),
              ),
              _buildLogoutRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 51),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _C.divider, width: 1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _C.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _text(15, FontWeight.w400, _C.navy),
              ),
            ),
            trailing ??
                const Icon(Icons.chevron_right, size: 18, color: _C.grey),
          ],
        ),
      ),
    );
  }

  /// Nút gạt "Chế độ tối" theo thiết kế (đang tắt, chức năng chưa có).
  Widget _buildSwitchPreview() {
    return Container(
      width: 48,
      height: 28,
      padding: const EdgeInsets.all(3),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: _C.switchOff,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildLogoutRow() {
    return InkWell(
      onTap: isLoggingOut ? null : _showLogoutDialog,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 50),
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            isLoggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _C.logout,
                    ),
                  )
                : const Icon(Icons.logout, size: 20, color: _C.logout),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isLoggingOut ? 'Đang đăng xuất...' : 'Đăng xuất',
                style: _text(15, FontWeight.w400, _C.logout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}