import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';

/// Phụ huynh tự đăng ký con. Nhà trường sẽ xem xét và duyệt trên hệ thống quản lý.
class RegisterChildPage extends ConsumerStatefulWidget {
  const RegisterChildPage({super.key});
  @override
  ConsumerState<RegisterChildPage> createState() => _RegisterChildPageState();
}

class _RegisterChildPageState extends ConsumerState<RegisterChildPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _class = TextEditingController();
  DateTime? _dob;
  String? _gender;
  String _relationship = 'FATHER';
  bool _loading = false;

  static const _labels = {
    'FATHER': 'Bố',
    'MOTHER': 'Mẹ',
    'GUARDIAN': 'Người giám hộ',
    'OTHER': 'Khác',
  };

  @override
  void dispose() {
    _name.dispose();
    _class.dispose();
    super.dispose();
  }

  InputDecoration _deco(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 7, 1, 1),
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      _snack('Vui lòng chọn ngày sinh của con');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(parentRepositoryProvider).registerChild(
            fullName: _name.text,
            dateOfBirth: _dob!,
            gender: _gender,
            className: _class.text,
            relationship: _relationship,
          );
      ref.invalidate(childrenProvider);
      if (!mounted) return;
      _snack('Đã gửi đăng ký, vui lòng chờ nhà trường duyệt');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _snack(_friendly(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _friendly(Object e) {
    final t = e.toString();
    const map = {
      'PARENT_PROFILE_NOT_FOUND': 'Tài khoản chưa có hồ sơ phụ huynh, vui lòng liên hệ nhà trường',
      'INVALID_NAME': 'Họ tên không hợp lệ (không được để trống, tối đa 150 ký tự)',
      'INVALID_DOB': 'Ngày sinh không hợp lệ',
      'INVALID_GENDER': 'Giới tính không hợp lệ',
      'INVALID_CLASS': 'Tên lớp quá dài (tối đa 50 ký tự)',
      'ALREADY_REQUESTED': 'Bạn đã đăng ký em này rồi',
      'TOO_MANY_PENDING': 'Bạn có quá nhiều yêu cầu đang chờ duyệt, vui lòng đợi nhà trường xử lý',
      'TOO_MANY_CHILDREN': 'Bạn đã đăng ký quá nhiều học sinh, vui lòng liên hệ nhà trường',
    };
    for (final entry in map.entries) {
      if (t.contains(entry.key)) return entry.value;
    }
    return 'Có lỗi xảy ra: $e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký con')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nhập thông tin của con. Nhà trường sẽ kiểm tra và duyệt đăng ký của bạn.',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: _deco('Họ và tên của con'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDob,
                child: InputDecorator(
                  decoration: _deco('Ngày sinh'),
                  child: Text(
                    _dob == null ? 'Chọn ngày sinh' : DateFormat('dd/MM/yyyy').format(_dob!),
                    style: TextStyle(color: _dob == null ? Colors.black45 : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: _deco('Giới tính'),
                items: const [
                  DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                  DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                ],
                onChanged: (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _class,
                decoration: _deco('Lớp (không bắt buộc, ví dụ 3A)'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _relationship,
                decoration: _deco('Quan hệ với con'),
                items: [
                  for (final e in _labels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _relationship = v ?? 'FATHER'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Gửi đăng ký'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}