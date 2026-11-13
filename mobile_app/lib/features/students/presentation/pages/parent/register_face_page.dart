import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_app/features/home/data/models/parent_models.dart';
import 'package:mobile_app/features/home/presentation/providers/parent_providers.dart';
import 'package:mobile_app/features/students/data/datasources/student_api.dart';
import 'package:mobile_app/features/students/data/services/face_embedder.dart';
import 'package:mobile_app/features/students/presentation/providers/student_providers.dart';

class _Pose {
  const _Pose(this.code, this.title, this.desc);
  final String code;
  final String title;
  final String desc;
}

const _poses = <_Pose>[
  _Pose('CENTER', 'Nhìn thẳng trực diện',
      'Giữ khuôn mặt ở chính giữa khung hình, nhìn thẳng vào camera.'),
  _Pose('LEFT', 'Quay mặt sang trái nhẹ', 'Hơi nghiêng hoặc quay đầu sang bên trái một chút.'),
  _Pose('RIGHT', 'Quay mặt sang phải nhẹ', 'Hơi nghiêng hoặc quay đầu sang bên phải một chút.'),
];

class _FaceSample {
  const _FaceSample(this.file, this.vector);
  final File file;
  final Float32List vector;
}

/// Phụ huynh chụp ảnh khuôn mặt của con để nhận diện điểm danh.
///  - Ảnh chỉ dùng để tạo vector NGAY TRÊN MÁY; hệ thống chỉ lưu vector.
///  - Ảnh nhận diện bị xóa khỏi điện thoại sau khi đăng ký (thành công hay hủy đều xóa).
///  - Ảnh đại diện là việc RIÊNG: chỉ khi phụ huynh chọn thì ảnh nhìn thẳng mới được dùng làm ảnh đại diện.
class RegisterFacePage extends ConsumerStatefulWidget {
  const RegisterFacePage({super.key, required this.child});
  final ChildInfo child;

  @override
  ConsumerState<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends ConsumerState<RegisterFacePage> {
  final ImagePicker _picker = ImagePicker();
  // Khóa theo góc mặt (CENTER/LEFT/RIGHT) nên chụp ô nào cũng đúng ô đó
  final Map<String, _FaceSample> _samples = {};
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _clearPhotos();
    super.dispose();
  }

  void _deleteFile(File f) {
    try {
      f.deleteSync();
    } catch (_) {}
  }

  void _clearPhotos() {
    for (final s in _samples.values) {
      _deleteFile(s.file);
    }
    _samples.clear();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _capture(_Pose p) async {
    File? file;
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (x == null) return;
      file = File(x.path);
      if (!mounted) {
        _deleteFile(file);
        return;
      }
      setState(() {
        _busy = true;
        _error = null;
      });

      final vector = await ref.read(faceEmbedderProvider).embed(file);
      if (!mounted) {
        _deleteFile(file);
        return;
      }
      final taken = file;
      setState(() {
        final old = _samples[p.code];
        if (old != null) _deleteFile(old.file);
        _samples[p.code] = _FaceSample(taken, vector);
      });
    } on FaceNotDetectedException catch (e) {
      if (file != null) _deleteFile(file);
      if (mounted) setState(() => _error = '${p.title}: ${e.message}');
    } catch (e) {
      if (file != null) _deleteFile(file);
      if (mounted) setState(() => _error = friendlyStudentError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Hỏi phụ huynh có muốn dùng ảnh nhìn thẳng làm ảnh đại diện không (mặc định là KHÔNG).
  Future<bool> _askUseAsAvatar() async {
    final r = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Dùng làm ảnh đại diện?'),
        content: const Text(
          'Ảnh dùng để nhận diện sẽ được xóa khỏi điện thoại, hệ thống chỉ lưu vector.\n\n'
          'Bạn có muốn dùng ảnh nhìn thẳng làm ảnh đại diện của con không? '
          'Ảnh đại diện là ảnh riêng, hiển thị trong hồ sơ và giúp cô giáo, tài xế nhận ra con. '
          'Bạn có thể đổi hoặc gỡ bất cứ lúc nào, kể cả khi thu hồi đồng ý khuôn mặt.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không dùng')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Dùng làm ảnh đại diện')),
        ],
      ),
    );
    return r ?? false;
  }

  Future<void> _submit() async {
    if (_samples.length < _poses.length) {
      _snack('Vui lòng chụp đủ ${_poses.length} góc mặt');
      return;
    }
    final id = widget.child.studentId;
    final embedder = ref.read(faceEmbedderProvider);

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // 1. Chỉ gửi VECTOR lên server
      await StudentManageApi.registerFace(
        studentId: id,
        modelName: embedder.modelName,
        vectors: [for (final p in _poses) _samples[p.code]!.vector],
        poses: [for (final p in _poses) p.code],
      );

      // 2. Ảnh đại diện: chỉ khi phụ huynh đồng ý. Lỗi ở bước này KHÔNG làm hỏng việc đăng ký.
      String? note;
      if (mounted && await _askUseAsAvatar()) {
        try {
          await StudentManageApi.setAvatar(
            studentId: id,
            file: _samples['CENTER']!.file,
            previousUrl: widget.child.avatarUrl,
          );
        } catch (e) {
          note = 'Đã đăng ký khuôn mặt nhưng chưa cập nhật được ảnh đại diện: '
              '${friendlyStudentError(e)}';
        }
      }

      // 3. Xóa toàn bộ ảnh tạm trên máy
      _clearPhotos();
      ref.invalidate(childrenProvider);
      ref.invalidate(childDetailProvider(id));
      ref.invalidate(childFaceStatusProvider(id));

      if (!mounted) return;
      _snack(note ?? 'Đã đăng ký khuôn mặt của con');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyStudentError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final embedder = ref.watch(faceEmbedderProvider);
    final status = ref.watch(childFaceStatusProvider(widget.child.studentId)).asData?.value;
    final consented = status?.isGranted ?? false;
    final allTaken = _poses.every((p) => _samples.containsKey(p.code));
    final canSubmit = allTaken && consented && !_busy;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5FF),
      appBar: AppBar(
        title: Text('Đăng ký khuôn mặt: ${widget.child.fullName}'),
        backgroundColor: const Color(0xFF1D4ED8),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Hướng dẫn đăng ký khuôn mặt',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10224A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chụp 3 góc mặt khác nhau để xe buýt điểm danh tự động chính xác. '
                'Chọn nơi đủ sáng, chỉ có khuôn mặt của con trong ảnh.',
                style: TextStyle(color: Color(0xFF52628A), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              if (status != null && !consented)
                const _Notice(
                  bg: Color(0xFFFCE4E1),
                  fg: Color(0xFF9B2C22),
                  icon: Icons.gpp_maybe_outlined,
                  text: 'Bạn cần đồng ý sử dụng khuôn mặt trước khi đăng ký. '
                      'Hãy quay lại hồ sơ của con và bấm "Đồng ý sử dụng".',
                ),
              if (embedder.isFake)
                _Notice(
                  bg: const Color(0xFFFEF3C7),
                  fg: const Color(0xFF7A4A00),
                  icon: Icons.science_outlined,
                  text: 'Chế độ thử nghiệm: đang dùng vector giả (${embedder.modelName}) để thử '
                      'luồng đăng ký, chưa dùng để điểm danh thật.',
                ),
              const _Notice(
                bg: Color(0xFFE0ECFF),
                fg: Color(0xFF1E3A8A),
                icon: Icons.lock_outline,
                text: 'Ảnh chỉ dùng để tạo vector ngay trên điện thoại rồi bị xóa. '
                    'Hệ thống chỉ lưu vector, không lưu ảnh dùng để nhận diện.',
              ),
              const SizedBox(height: 4),
              for (final p in _poses)
                _PoseCard(
                  pose: p,
                  sample: _samples[p.code],
                  enabled: !_busy,
                  onCapture: () => _capture(p),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(_error!,
                      style: const TextStyle(color: Color(0xFFC8382F), fontSize: 13)),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: canSubmit ? _submit : null,
                  child: Text(
                    allTaken
                        ? 'Hoàn tất đăng ký khuôn mặt'
                        : 'Chụp đủ ${_poses.length} góc (${_samples.length}/${_poses.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({
    required this.pose,
    required this.sample,
    required this.enabled,
    required this.onCapture,
  });
  final _Pose pose;
  final _FaceSample? sample;
  final bool enabled;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final taken = sample != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                image: taken
                    ? DecorationImage(image: FileImage(sample!.file), fit: BoxFit.cover)
                    : null,
              ),
              child: taken ? null : const Icon(Icons.camera_alt, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pose.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF10224A))),
                  const SizedBox(height: 4),
                  Text(pose.desc,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: enabled ? onCapture : null,
                    child: Text(
                      taken ? 'Chụp lại ảnh này' : 'Chụp ảnh ngay',
                      style: TextStyle(
                        color: enabled ? const Color(0xFF1D4ED8) : Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (taken) const Icon(Icons.check_circle, color: Colors.green, size: 28),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.bg, required this.fg, required this.icon, required this.text});
  final Color bg;
  final Color fg;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: fg, height: 1.4))),
        ],
      ),
    );
  }
}