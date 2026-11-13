import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // ----- Bảng màu (đồng bộ với trang đăng nhập) -----
  static const Color _headerColor = Color(0xFF1D4ED8);
  static const Color _headerDark = Color(0xFF1E40AF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textDark = Color(0xFF10224A);
  static const Color _textMuted = Color(0xFF52628A);
  static const Color _border = Color(0xFFC5D2EA);
  static const Color _infoBg = Color(0xFFE0ECFF);
  static const Color _infoText = Color(0xFF1E3A8A);
  static const Color _yellow = Color(0xFFFBBF24);

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Logic đăng ký (giữ nguyên, chỉ thêm kiểm tra ô trống)
  // ---------------------------------------------------------------------

  Future<void> register() async {
    if (isLoading) return;

    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      final hasSession = await ref.read(
        registerUseCaseProvider,
      )(
        fullName: name,
        email: email,
        password: passwordController.text,
      );

      if (!mounted) return;

      if (hasSession) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đăng ký thành công. Bạn có thể đăng nhập.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Đã tạo tài khoản. Vui lòng kiểm tra email để xác nhận.',
            ),
          ),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng ký thất bại: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------
  // Giao diện
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: _headerColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Stack(
        children: [
          // Vòng tròn trang trí
          Positioned(
            top: -70,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _headerDark,
              ),
            ),
          ),
          Positioned(
            top: 78,
            right: -8,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _yellow,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topInset + 12, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nút quay lại
                Material(
                  color: const Color(0x2EFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isLoading ? null : () => Navigator.maybePop(context),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0x2EFFFFFF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tạo tài khoản',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Dành cho phụ huynh theo dõi việc đưa đón của con',
                              style: TextStyle(
                                color: Color(0xFFDBE8FF),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
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
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Họ và tên
          _label('Họ và tên'),
          const SizedBox(height: 6),
          TextField(
            controller: nameController,
            enabled: !isLoading,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Nguyễn Văn A',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),

          // Email
          _label('Email'),
          const SizedBox(height: 6),
          TextField(
            controller: emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'phuhuynh@email.com',
              icon: Icons.mail_outline_rounded,
            ),
          ),
          const SizedBox(height: 14),

          // Mật khẩu
          _label('Mật khẩu'),
          const SizedBox(height: 6),
          TextField(
            controller: passwordController,
            enabled: !isLoading,
            obscureText: hidePassword,
            textInputAction: TextInputAction.next,
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Nhập mật khẩu',
              icon: Icons.lock_outline_rounded,
              suffix: _eyeButton(
                hidden: hidePassword,
                onTap: () => setState(() => hidePassword = !hidePassword),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Xác nhận mật khẩu
          _label('Xác nhận mật khẩu'),
          const SizedBox(height: 6),
          TextField(
            controller: confirmPasswordController,
            enabled: !isLoading,
            obscureText: hideConfirm,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) register();
            },
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: 'Nhập lại mật khẩu',
              icon: Icons.lock_reset_rounded,
              suffix: _eyeButton(
                hidden: hideConfirm,
                onTap: () => setState(() => hideConfirm = !hideConfirm),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Thẻ thông tin quyền mặc định
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _infoBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.verified_user_outlined,
                    size: 20,
                    color: _headerColor,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tài khoản đăng ký mới sẽ được cấp quyền PHỤ HUYNH mặc định.',
                    style: TextStyle(
                      color: _infoText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // Nút tạo tài khoản
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : register,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF93B4F5),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Tạo tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Quay lại đăng nhập
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Đã có tài khoản?',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: _headerColor,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Thành phần nhỏ
  // ---------------------------------------------------------------------

  static const TextStyle _inputTextStyle = TextStyle(
    color: _textDark,
    fontSize: 15,
    fontWeight: FontWeight.w400,
  );

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textDark,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _eyeButton({required bool hidden, required VoidCallback onTap}) {
    return IconButton(
      splashRadius: 22,
      icon: Icon(
        hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
        color: _textMuted,
      ),
      onPressed: onTap,
    );
  }

  OutlineInputBorder _outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF6B7A99),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      prefixIcon: Icon(icon, size: 22, color: _textMuted),
      prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 52),
      suffixIcon: suffix,
      suffixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 52),
      border: _outline(_border),
      enabledBorder: _outline(_border),
      disabledBorder: _outline(_border),
      focusedBorder: _outline(_primary, 1.6),
    );
  }
}