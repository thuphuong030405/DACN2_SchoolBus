import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_app/features/profile/domain/profile_exception.dart';
import 'package:mobile_app/features/profile/presentation/providers/profile_provider.dart';

/// Bảng đổi mật khẩu. Đóng lại với một câu thông báo khi đổi thành công.
///
/// Giao diện theo Figma: header xanh bo góc có vòng tròn trang trí,
/// thẻ trắng bo 16 trên nền xanh nhạt, danh sách điều kiện có tick,
/// nút chính xanh đậm full-width.
class ChangePasswordSheet extends ConsumerStatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  ConsumerState<ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<ChangePasswordSheet> {
  // ----- Bảng màu theo Figma -----
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color bgColor = Color(0xFFF3F6FD);
  static const Color lineColor = Color(0xFFE2E8F5);
  static const Color textColor = Color(0xFF0F172A);
  static const Color mutedColor = Color(0xFF64748B);
  static const Color successColor = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);

  static const int minLength = 8;

  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Validate + gửi (giữ nguyên logic cũ)
  // ---------------------------------------------------------------------

  String? _validateCurrent(String? value) {
    if ((value ?? '').isEmpty) return 'Vui lòng nhập mật khẩu hiện tại';
    return null;
  }

  String? _validateNew(String? value) {
    final text = value ?? '';
    if (text.length < minLength) {
      return 'Mật khẩu mới phải có ít nhất $minLength ký tự';
    }
    if (text == _currentController.text) {
      return 'Mật khẩu mới phải khác mật khẩu hiện tại';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if ((value ?? '').isEmpty) return 'Vui lòng nhập lại mật khẩu mới';
    if (value != _newController.text) return 'Mật khẩu nhập lại không khớp';
    return null;
  }

  Future<void> _submit() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(profileRepositoryProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );

      if (!mounted) return;
      Navigator.pop(context, 'Đổi mật khẩu thành công.');
    } on ProfileException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Có lỗi xảy ra, vui lòng thử lại.';
        _saving = false;
      });
    }
  }

  // ---------------------------------------------------------------------
  // Giao diện
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Container(
        color: bgColor,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: _buildBody(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header xanh có vòng tròn trang trí, giống các màn hình trong Figma.
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, primaryDark],
        ),
      ),
      child: Stack(
        children: [
          // Vòng tròn trang trí
          Positioned(
            top: -36,
            right: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1FFFFFFF),
              ),
            ),
          ),
          Positioned(
            top: 22,
            right: 92,
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x4DFFFFFF),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              children: [
                // Thanh kéo
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0x66FFFFFF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _roundIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _saving ? null : () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đổi mật khẩu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Bảo vệ tài khoản của bạn',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, VoidCallback? onTap}) {
    return Material(
      color: const Color(0x2EFFFFFF),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final newText = _newController.text;
    final okLength = newText.length >= minLength;
    final okDifferent =
        newText.isNotEmpty && newText != _currentController.text;
    final okMatch = newText.isNotEmpty && newText == _confirmController.text;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ nhập mật khẩu
          _card(
            child: Column(
              children: [
                _field(
                  label: 'Mật khẩu hiện tại',
                  hint: 'Nhập mật khẩu hiện tại',
                  controller: _currentController,
                  visible: _showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                  validator: _validateCurrent,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _field(
                  label: 'Mật khẩu mới',
                  hint: 'Ít nhất $minLength ký tự',
                  controller: _newController,
                  visible: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  validator: _validateNew,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _field(
                  label: 'Nhập lại mật khẩu mới',
                  hint: 'Nhập lại mật khẩu mới',
                  controller: _confirmController,
                  visible: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  validator: _validateConfirm,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Thẻ yêu cầu mật khẩu (tick xanh khi đạt)
          _card(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Yêu cầu mật khẩu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 10),
                _rule('Có ít nhất $minLength ký tự', okLength),
                const SizedBox(height: 8),
                _rule('Khác mật khẩu hiện tại', okDifferent),
                const SizedBox(height: 8),
                _rule('Nhập lại khớp với mật khẩu mới', okMatch),
              ],
            ),
          ),

          // Thông báo lỗi (thẻ đỏ nhạt như "Chưa thể chốt chuyến")
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dangerBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: dangerColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: dangerColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Nút chính
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF93B4F5),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_reset_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Đổi mật khẩu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),

          // Nút phụ (màu xanh xám nhạt như nút "Chốt chuyến")
          SizedBox(
            height: 46,
            child: TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFE6ECFA),
                foregroundColor: mutedColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Hủy',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Thành phần nhỏ
  // ---------------------------------------------------------------------

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: lineColor),
      ),
      child: child,
    );
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required TextInputAction action,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: mutedColor,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          enabled: !_saving,
          obscureText: !visible,
          textInputAction: action,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          // Cập nhật tick điều kiện theo thời gian thực, xoá lỗi cũ khi gõ lại
          onChanged: (_) => setState(() => _error = null),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: primaryColor,
            ),
            suffixIcon: IconButton(
              splashRadius: 20,
              icon: Icon(
                visible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 20,
                color: mutedColor,
              ),
              onPressed: onToggle,
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dangerColor,
            ),
            border: _border(lineColor),
            enabledBorder: _border(lineColor),
            disabledBorder: _border(lineColor),
            focusedBorder: _border(primaryColor, 1.6),
            errorBorder: _border(dangerColor),
            focusedErrorBorder: _border(dangerColor, 1.6),
          ),
        ),
      ],
    );
  }

  Widget _rule(String text, bool ok) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: ok ? successBg : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: ok ? successColor : const Color(0xFFCBD5E1),
              width: 1.4,
            ),
          ),
          child: ok
              ? const Icon(Icons.check_rounded, size: 14, color: successColor)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ok ? successColor : mutedColor,
            ),
          ),
        ),
      ],
    );
  }
}