import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/students/data/datasources/student_api.dart';
import 'package:mobile_app/features/students/data/models/student_model.dart';
import 'package:mobile_app/features/students/presentation/providers/student_providers.dart';

/// Phụ huynh sửa thông tin con. Chỉ sửa được: họ tên, ngày sinh, giới tính, lớp và ảnh đại diện.
/// Mã học sinh, tuyến xe, điểm đón do nhà trường quản lý (hàm update_my_child ở DB cũng chặn).
/// Ảnh đại diện là ảnh RIÊNG, không dùng để nhận diện khuôn mặt.
class EditChildPage extends ConsumerStatefulWidget {
  const EditChildPage({super.key, required this.detail});
  final ChildDetail detail;

  @override
  ConsumerState<EditChildPage> createState() => _EditChildPageState();
}

class _EditChildPageState extends ConsumerState<EditChildPage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.detail.fullName);
  late final _class = TextEditingController(text: widget.detail.className ?? '');
  late DateTime _dob = widget.detail.dateOfBirth;
  late String? _gender = widget.detail.gender;
  late String? _avatarUrl = widget.detail.avatarUrl;
  File? _localPreview; // ảnh vừa chọn, hiện ngay kể cả khi đường dẫn công khai chưa mở được
  bool _saving = false;
  bool _avatarBusy = false;

  @override
  void dispose() {
    _name.dispose();
    _class.dispose();
    try {
      _localPreview?.deleteSync();
    } catch (_) {}
    super.dispose();
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC5D2EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC5D2EA)),
        ),
      );

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ------------------------------------------------------------ ảnh đại diện

  void _refreshChildData() {
    final id = widget.detail.studentId;
    ref.invalidate(childDetailProvider(id));
    ref.invalidate(childrenProvider);
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final x = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;

    final file = File(x.path);
    setState(() => _avatarBusy = true);
    try {
      final url = await StudentManageApi.setAvatar(
        studentId: widget.detail.studentId,
        file: file,
        previousUrl: _avatarUrl,
      );
      _refreshChildData();
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _localPreview = file;
      });
      _snack('Đã cập nhật ảnh đại diện');
    } catch (e) {
      if (!mounted) return;
      _snack(friendlyStudentError(e));
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _avatarBusy = true);
    try {
      await StudentManageApi.removeAvatar(
        studentId: widget.detail.studentId,
        currentUrl: _avatarUrl,
      );
      _refreshChildData();
      if (!mounted) return;
      setState(() {
        _avatarUrl = null;
        _localPreview = null;
      });
      _snack('Đã gỡ ảnh đại diện');
    } catch (e) {
      if (!mounted) return;
      _snack(friendlyStudentError(e));
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  void _openAvatarMenu() {
    final hasAvatar = _localPreview != null || (_avatarUrl?.isNotEmpty ?? false);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Color(0xFFC8382F)),
                title: const Text('Gỡ ảnh đại diện',
                    style: TextStyle(color: Color(0xFFC8382F))),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _removeAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    const size = 88.0;
    final name = _name.text.trim();
    final initial =
        name.isEmpty ? '?' : String.fromCharCode(name.runes.first).toUpperCase();

    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: Color(0xFF1D4ED8), shape: BoxShape.circle),
      child: Text(initial,
          style: const TextStyle(
              fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700)),
    );

    Widget picture = fallback;
    if (_localPreview != null) {
      picture = ClipOval(
        child: Image.file(_localPreview!, width: size, height: size, fit: BoxFit.cover),
      );
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      picture = ClipOval(
        child: Image.network(
          _avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    return GestureDetector(
      onTap: _avatarBusy ? null : _openAvatarMenu,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            picture,
            if (_avatarBusy)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFC5D2EA)),
                ),
                child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF1D4ED8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- thông tin

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Khớp giới hạn ở DB: không ở tương lai, không quá 9131 ngày (khoảng 25 tuổi)
    final first = today.subtract(const Duration(days: 9131));
    var initial = _dob;
    if (initial.isAfter(today)) initial = today;
    if (initial.isBefore(first)) initial = first;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: today,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.detail.studentId;
    setState(() => _saving = true);
    try {
      await StudentManageApi.updateChild(
        studentId: id,
        fullName: _name.text,
        dateOfBirth: _dob,
        gender: _gender,
        className: _class.text,
      );
      ref.invalidate(childDetailProvider(id));
      ref.invalidate(childrenProvider);
      ref.invalidate(childProfileInfoProvider(id));
      if (!mounted) return;
      _snack('Đã lưu thông tin của con');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      _snack(friendlyStudentError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      appBar: AppBar(
        title: const Text('Sửa thông tin của con'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: _avatar()),
            const SizedBox(height: 8),
            const Text(
              'Ảnh đại diện là ảnh riêng, không dùng để nhận diện khuôn mặt. '
              'Cô giáo và tài xế thấy ảnh này để nhận ra con.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF52628A), height: 1.4),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _deco('Họ tên'),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return 'Vui lòng nhập họ tên';
                if (s.length > 150) return 'Họ tên tối đa 150 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: _deco('Ngày sinh').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                ),
                child: Text(DateFormat('dd/MM/yyyy').format(_dob)),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String?>(
              value: _gender,
              decoration: _deco('Giới tính'),
              items: const <DropdownMenuItem<String?>>[
                DropdownMenuItem(value: null, child: Text('Chưa chọn')),
                DropdownMenuItem(value: 'MALE', child: Text('Nam')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Nữ')),
                DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _class,
              decoration: _deco('Lớp'),
              validator: (v) =>
                  (v?.trim().length ?? 0) > 50 ? 'Tên lớp tối đa 50 ký tự' : null,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3EAF7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF52628A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Mã học sinh: ${widget.detail.studentCode} (do nhà trường quản lý, không sửa được)',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF52628A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE0ECFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Mọi thay đổi được ghi lại (ai sửa, sửa gì, lúc nào). Tuyến xe và điểm đón '
                'do nhà trường xếp, nếu cần đổi hãy liên hệ nhà trường.',
                style: TextStyle(fontSize: 12, color: Color(0xFF1E3A8A), height: 1.4),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: (_saving || _avatarBusy) ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Lưu thay đổi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}