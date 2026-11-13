import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _showCurrent = false, _showNew = false, _showConfirm = false;
  bool _saving = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(parentRepositoryProvider).changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã đổi mật khẩu')));
      Navigator.of(context).pop();
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'invalid_credentials' => 'Mật khẩu hiện tại không đúng',
        'same_password' => 'Mật khẩu mới phải khác mật khẩu cũ',
        'weak_password' => 'Mật khẩu mới quá yếu',
        _ => e.message.contains('Invalid login credentials')
            ? 'Mật khẩu hiện tại không đúng'
            : 'Không đổi được mật khẩu: ${e.message}',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required bool visible,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off : Icons.visibility),
          onPressed: onToggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      appBar: AppBar(
        title: const Text(
          'Đổi mật khẩu',
          style: TextStyle(
            color: Color(0xFF10224A),
            fontFamily: 'Be Vietnam Pro',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              label: 'Mật khẩu hiện tại',
              controller: _current,
              visible: _showCurrent,
              onToggle: () => setState(() => _showCurrent = !_showCurrent),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
            ),
            const SizedBox(height: 16),
            _field(
              label: 'Mật khẩu mới',
              controller: _new,
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
              validator: (v) {
                final s = v ?? '';
                if (s.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
                if (s == _current.text) return 'Mật khẩu mới phải khác mật khẩu hiện tại';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _field(
              label: 'Nhập lại mật khẩu mới',
              controller: _confirm,
              visible: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
              validator: (v) => v != _new.text ? 'Mật khẩu nhập lại không khớp' : null,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sau khi đổi, các thiết bị khác đang đăng nhập tài khoản này sẽ bị đăng xuất.',
              style: TextStyle(color: Color(0xFF52628A), fontSize: 12, fontFamily: 'Be Vietnam Pro'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Cập nhật mật khẩu',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Be Vietnam Pro'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

