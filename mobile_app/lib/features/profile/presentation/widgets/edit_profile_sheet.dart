import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_app/features/profile/domain/profile_exception.dart';
import 'package:mobile_app/features/profile/presentation/providers/profile_provider.dart';

/// Bảng chỉnh sửa họ tên, số điện thoại và email.
/// Đóng lại với một câu thông báo khi lưu thành công.
class EditProfileSheet extends ConsumerStatefulWidget {
  final String initialName;
  final String initialEmail;
  final String? initialPhone;

  const EditProfileSheet({
    super.key,
    required this.initialName,
    required this.initialEmail,
    this.initialPhone,
  });

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  // ----- Bảng màu theo Figma -----
  static const Color primaryColor = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color bgColor = Color(0xFFF3F6FD);
  static const Color lineColor = Color(0xFFE2E8F5);
  static const Color textColor = Color(0xFF0F172A);
  static const Color mutedColor = Color(0xFF64748B);
  static const Color dangerColor = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color infoBg = Color(0xFFE8F0FE);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _phoneController = TextEditingController(text: widget.initialPhone ?? '');
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Validate + lưu
  // ---------------------------------------------------------------------

  /// Bỏ khoảng trắng, dấu chấm, gạch ngang để so sánh và lưu cho gọn.
  String _normalizePhone(String? value) =>
      (value ?? '').replaceAll(RegExp(r'[\s.\-]'), '');

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Họ và tên phải có ít nhất 2 ký tự';
    if (text.length > 150) return 'Họ và tên quá dài';
    return null;
  }

  /// Số điện thoại không bắt buộc. Nếu nhập thì phải đúng dạng số Việt Nam:
  /// 0xxxxxxxxx (10 số) hoặc +84xxxxxxxxx.
  String? _validatePhone(String? value) {
    final text = _normalizePhone(value);
    if (text.isEmpty) return null;
    if (!RegExp(r'^(0|\+84)[0-9]{9}$').hasMatch(text)) {
      return 'Số điện thoại không hợp lệ (ví dụ: 0901234567)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Vui lòng nhập email';
    if (text.length > 255) return 'Email quá dài';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameController.text.trim();
    final phone = _normalizePhone(_phoneController.text);
    final email = _emailController.text.trim();

    final nameChanged = name != widget.initialName;
    final phoneChanged = phone != _normalizePhone(widget.initialPhone);
    final emailChanged =
        email.toLowerCase() != widget.initialEmail.toLowerCase();

    if (!nameChanged && !phoneChanged && !emailChanged) {
      Navigator.pop(context);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    final repository = ref.read(profileRepositoryProvider);

    try {
      if (nameChanged) {
        await repository.updateFullName(name);
      }

      if (phoneChanged) {
        // Để trống = xoá số điện thoại
        await repository.updatePhone(phone.isEmpty ? null : phone);
      }

      if (nameChanged || phoneChanged) {
        ref.invalidate(userProfileProvider);
      }

      if (emailChanged) {
        await repository.requestEmailChange(email);
      }

      if (!mounted) return;

      Navigator.pop(
        context,
        emailChanged
            ? 'Đã lưu. Hãy kiểm tra hộp thư của email mới để xác nhận việc đổi email.'
            : 'Đã cập nhật thông tin cá nhân.',
      );
    } on ProfileException catch (e) {
      if (!mounted) return;
      // Tên/SĐT có thể đã lưu trước khi email lỗi -> làm mới dữ liệu hiển thị
      ref.invalidate(userProfileProvider);
      setState(() {
        _error = e.message;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      ref.invalidate(userProfileProvider);
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
                    Material(
                      color: const Color(0x2EFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _saving ? null : () => Navigator.pop(context),
                        child: const SizedBox(
                          width: 38,
                          height: 38,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chỉnh sửa thông tin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Cập nhật họ tên, số điện thoại và email',
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

  Widget _buildBody() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thẻ nhập thông tin
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: lineColor),
            ),
            child: Column(
              children: [
                _field(
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên',
                  icon: Icons.person_outline_rounded,
                  controller: _nameController,
                  validator: _validateName,
                  capitalization: TextCapitalization.words,
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _field(
                  label: 'Số điện thoại',
                  hint: 'Ví dụ: 0901234567',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  validator: _validatePhone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s.\-]')),
                    LengthLimitingTextInputFormatter(16),
                  ],
                  action: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                _field(
                  label: 'Email',
                  hint: 'Nhập email',
                  icon: Icons.email_outlined,
                  controller: _emailController,
                  validator: _validateEmail,
                  keyboardType: TextInputType.emailAddress,
                  action: TextInputAction.done,
                  onSubmitted: (_) => _save(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ghi chú
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: infoBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFD3FB)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: primaryColor, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Khi đổi email, hệ thống sẽ gửi thư xác nhận tới email mới. '
                    'Email chỉ thay đổi sau khi bạn xác nhận. '
                    'Số điện thoại có thể để trống.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF1E40AF),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thông báo lỗi
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
              onPressed: _saving ? null : _save,
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
                        Icon(Icons.check_circle_outline_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Lưu thay đổi',
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

          // Nút phụ
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

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _field({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required TextInputAction action,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
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
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          textInputAction: action,
          inputFormatters: inputFormatters,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
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
            prefixIcon: Icon(icon, size: 20, color: primaryColor),
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
}