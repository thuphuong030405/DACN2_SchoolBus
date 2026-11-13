import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';

class LinkChildPage extends ConsumerStatefulWidget {
  const LinkChildPage({super.key});
  @override
  ConsumerState<LinkChildPage> createState() => _LinkChildPageState();
}

class _LinkChildPageState extends ConsumerState<LinkChildPage> {
  final _code = TextEditingController();
  String _relationship = 'FATHER';
  bool _loading = false;

  static const _labels = {
    'FATHER': 'Bố',
    'MOTHER': 'Mẹ',
    'GUARDIAN': 'Người giám hộ',
    'OTHER': 'Khác',
  };

  Future<void> _submit() async {
    if (_code.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã học sinh')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(parentRepositoryProvider).requestLinkStudent(
            studentCode: _code.text,
            relationship: _relationship,
          );
      ref.invalidate(childrenProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã gửi yêu cầu, vui lòng chờ nhà trường duyệt'),
      ));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = _friendly(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e) {
    final t = e.toString();
    if (t.contains('STUDENT_NOT_FOUND')) return 'Không tìm thấy mã học sinh này';
    if (t.contains('ALREADY_LINKED')) return 'Con đã được liên kết với tài khoản của bạn';
    if (t.contains('ALREADY_REQUESTED')) {
      return 'Bạn đã gửi yêu cầu này, vui lòng chờ nhà trường duyệt';
    }
    if (t.contains('PARENT_PROFILE_NOT_FOUND')) {
      return 'Tài khoản chưa có hồ sơ phụ huynh, vui lòng liên hệ nhà trường';
    }
    return 'Có lỗi xảy ra: $e';
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên kết với con')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _code,
              decoration: const InputDecoration(
                labelText: 'Mã học sinh',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _relationship,
              decoration: const InputDecoration(
                labelText: 'Quan hệ với học sinh',
                border: OutlineInputBorder(),
              ),
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
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Gửi yêu cầu'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}