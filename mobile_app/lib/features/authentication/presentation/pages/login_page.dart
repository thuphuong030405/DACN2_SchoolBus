import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // ----- Bảng màu theo Figma -----
  static const Color _headerColor = Color(0xFF1D4ED8);
  static const Color _headerDark = Color(0xFF1E40AF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textDark = Color(0xFF10224A);
  static const Color _textMuted = Color(0xFF52628A);
  static const Color _border = Color(0xFFC5D2EA);
  static const Color _infoBg = Color(0xFFE0ECFF);
  static const Color _infoText = Color(0xFF1E3A8A);
  static const Color _yellow = Color(0xFFFBBF24);

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  // Chỉ là lựa chọn giao diện: Supabase vốn đã lưu phiên đăng nhập trên máy.
  bool rememberMe = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // Logic đăng nhập (giữ nguyên)
  // ---------------------------------------------------------------------

  Future<void> login() async {
    if (isLoading) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập email và mật khẩu'),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      isLoading = true;
    });

    try {
      // 1. Thực hiện đăng nhập qua UseCase
      await ref.read(loginUseCaseProvider)(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // 2. Ép buộc làm mới và fetch lại dữ liệu user ngay lập tức để AuthGate kích hoạt chuyển trang
      ref.invalidate(currentUserProvider);
      await ref.read(currentUserProvider.future);

      if (!mounted) return;

      debugPrint('LOGIN SUCCESS & REFRESHED GATE');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đăng nhập thất bại: $e'),
          backgroundColor: Colors.red,
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

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  void _forgotPassword() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Vui lòng liên hệ nhà trường để được cấp lại mật khẩu.',
        ),
      ),
    );
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        Expanded(child: _buildForm()),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Header xanh bo góc dưới 36: minh hoạ xe buýt vàng trên đường,
  /// đám mây, vòng tròn trang trí, tiêu đề căn giữa (theo Figma).
  Widget _buildHeader(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 250),
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
          // Vòng tròn xanh đậm góc trên bên phải
          Positioned(
            top: -80,
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
          Padding(
            padding: EdgeInsets.fromLTRB(24, topInset + 14, 24, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Minh hoạ xe buýt + chấm vàng ở mép phải
                SizedBox(
                  width: double.infinity,
                  height: 110,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.topCenter,
                    children: [
                      const CustomPaint(
                        size: Size(230, 110),
                        painter: _BusIllustrationPainter(),
                      ),
                      Positioned(
                        right: -14,
                        top: 35,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _yellow,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Bus An Toàn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Đưa đón an toàn, yên tâm mỗi ngày',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFDBE8FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
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
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Đăng nhập',
            style: TextStyle(
              color: _textDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Dành cho phụ huynh, giáo viên và tài xế',
            style: TextStyle(
              color: _textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w400,
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
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!isLoading) login();
            },
            style: _inputTextStyle,
            decoration: _inputDecoration(
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              suffix: IconButton(
                splashRadius: 22,
                icon: Icon(
                  hidePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                  color: _textMuted,
                ),
                onPressed: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Ghi nhớ + Quên mật khẩu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: isLoading
                    ? null
                    : () => setState(() => rememberMe = !rememberMe),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: rememberMe ? _primary : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: rememberMe ? _primary : _border,
                            width: 1.4,
                          ),
                        ),
                        child: rememberMe
                            ? const Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ghi nhớ đăng nhập',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: isLoading ? null : _forgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: _headerColor,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Quên mật khẩu?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),

          // Nút đăng nhập
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: isLoading ? null : login,
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
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),

          // Đăng ký
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Phụ huynh chưa có tài khoản?',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextButton(
                  onPressed: isLoading ? null : _openRegister,
                  style: TextButton.styleFrom(
                    foregroundColor: _headerColor,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Đăng ký',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // Đẩy thẻ thông tin xuống đáy màn hình
          const Spacer(),
          const SizedBox(height: 24),

          // Thẻ thông tin có icon khiên
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
                    'Giáo viên và tài xế: tài khoản do nhà trường cấp. '
                    'Liên hệ nhà trường nếu bạn chưa nhận được thông tin đăng nhập.',
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

/// Vẽ minh hoạ xe buýt vàng trên con đường + đám mây (khung 230 x 110).
class _BusIllustrationPainter extends CustomPainter {
  const _BusIllustrationPainter();

  static const Color _navy = Color(0xFF10224A);
  static const Color _busYellow = Color(0xFFFACC15);
  static const Color _window = Color(0xFFDBEAFE);

  @override
  void paint(Canvas canvas, Size size) {
    // Đám mây trắng
    final cloud = Paint()..color = Colors.white;
    canvas.drawOval(const Rect.fromLTWH(46, 8, 50, 13), cloud);
    canvas.drawOval(const Rect.fromLTWH(60, 2, 26, 14), cloud);
    canvas.drawOval(const Rect.fromLTWH(86, 9, 16, 9), cloud);

    // Con đường
    final road = Paint()..color = _navy;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 102, 230, 5),
        const Radius.circular(2.5),
      ),
      road,
    );

    // Thân xe
    final bodyRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(36, 26, 158, 66),
      const Radius.circular(16),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = _busYellow);

    // Cửa sổ
    final windowPaint = Paint()..color = _window;
    for (var i = 0; i < 4; i++) {
      final left = 47.0 + i * 36.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 37, 28, 22),
          const Radius.circular(6),
        ),
        windowPaint,
      );
    }

    // Dải xanh đậm dưới cửa sổ
    canvas.save();
    canvas.clipRRect(bodyRRect);
    canvas.drawRect(const Rect.fromLTWH(36, 68, 158, 6), Paint()..color = _navy);
    canvas.restore();

    // Bánh xe
    final wheel = Paint()..color = _navy;
    final hub = Paint()..color = _window;
    for (final cx in const [76.0, 154.0]) {
      canvas.drawCircle(Offset(cx, 94), 12, wheel);
      canvas.drawCircle(Offset(cx, 94), 5, hub);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}