import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/core/services/storage_service.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key, required this.profile});
  final ParentProfile profile;

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.profile.fullName);
  late final _phone = TextEditingController(text: widget.profile.phone ?? '');
  late final _address = TextEditingController(text: widget.profile.address ?? '');
  late final _job = TextEditingController(text: widget.profile.occupation ?? '');
  
  File? _newAvatarFile;
  final ImagePicker _picker = ImagePicker();
  bool _saving = false;

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _newAvatarFile = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // 1. Nếu phụ huynh chọn ảnh đại diện mới thì upload lên Storage
      if (_newAvatarFile != null) {
        final avatarUrl = await StorageService.uploadAvatar(
          file: _newAvatarFile!,
          folder: 'parents',
          id: userId,
        );
        await Supabase.instance.client.rpc('update_my_avatar', params: {
          'p_avatar_url': avatarUrl,
        });
      }

      // 2. Lưu thông tin cá nhân
      await ref.read(parentRepositoryProvider).updateMyProfile(
            fullName: _name.text,
            phone: _phone.text,
            address: _address.text,
            occupation: _job.text,
          );
      
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('23505')
          ? 'Số điện thoại này đã được sử dụng'
          : 'Không lưu được: $e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _job.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration deco(String l) =>
        InputDecoration(labelText: l, border: const OutlineInputBorder());

    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa thông tin')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Giao diện chọn ảnh đại diện
            Center(
              child: Stack(
                children: [
                CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _newAvatarFile != null
                        ? FileImage(_newAvatarFile!) as ImageProvider
                        : (widget.profile.avatarUrl != null && widget.profile.avatarUrl!.isNotEmpty
                            ? NetworkImage(widget.profile.avatarUrl!) as ImageProvider
                            : null),
                    child: (_newAvatarFile == null && (widget.profile.avatarUrl == null || widget.profile.avatarUrl!.isEmpty))
                        ? const Icon(Icons.person, size: 40, color: Colors.white)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        onPressed: _pickAvatar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: deco('Họ tên'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: deco('Số điện thoại'),
              keyboardType: TextInputType.phone,
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return null;
                return RegExp(r'^(0|\+84)\d{9}$').hasMatch(s) ? null : 'Số điện thoại không hợp lệ';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: deco('Địa chỉ'), maxLines: 2),
            const SizedBox(height: 12),
            TextFormField(controller: _job, decoration: deco('Nghề nghiệp')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}