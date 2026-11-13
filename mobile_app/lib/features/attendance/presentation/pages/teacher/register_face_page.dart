import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_embedding_helper.dart';
import 'mobile_facenet_service.dart'; // 🟢 Import service AI MobileFaceNet

class RegisterFacePage extends StatefulWidget {
  final String studentId;
  final String studentName;
  final String? parentId;

  const RegisterFacePage({
    super.key,
    required this.studentId,
    required this.studentName,
    this.parentId,
  });

  @override
  State<RegisterFacePage> createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage> {
  final _supabase = Supabase.instance.client;
  CameraController? _cameraController;
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
    ),
  );

  // 🟢 Khởi tạo Service AI TFLite
  final MobileFaceNetService _faceNetService = MobileFaceNetService();

  bool _isProcessing = false;
  String _statusText = 'Căn mặt học sinh vào khung và bấm CHỤP';

  @override
  void initState() {
    super.initState();
    _initCamera();
    _faceNetService.loadModel().catchError((e) => debugPrint('🔴 Lỗi nạp model: $e'));
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final frontCam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      frontCam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _faceNetService.close(); // 🟢 Đóng mô hình TFLite giải phóng bộ nhớ
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _captureAndSaveFace() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusText = 'Đang phân tích khuôn mặt bằng AI...';
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        throw Exception('Không phát hiện khuôn mặt! Vui lòng căn giữa camera và chụp lại.');
      }

      // 🟢 1. Trích xuất Vector AI 192 chiều từ mô hình MobileFaceNet
      final List<double> embeddingVector = await _faceNetService.extractEmbedding(
        imageFile.path,
        faces.first,
      );

      if (embeddingVector.isEmpty) {
        throw Exception('Không nhận diện được khuôn mặt trong ảnh. Hãy chụp lại, nhìn thẳng và đủ sáng.');
      }

      // 2. Ép kiểu Vector sang chuỗi Hex nhị phân PostgreSQL BYTEA (\x...)
      final String hexBytea = FaceEmbeddingHelper.float32ListToHexBytea(embeddingVector);

      setState(() => _statusText = 'Đang lưu vào CSDL Supabase...');

      // 3. Xóa vector cũ nếu có
      await _supabase.from('face_embeddings').delete().eq('student_id', widget.studentId);

      // 4. Chèn vector AI mới với dimension 192
      final bool hasConsent = widget.parentId != null;

      await _supabase.from('face_embeddings').insert({
        'student_id': widget.studentId,
        'embedding_data': hexBytea,
        'model_name': 'MobileFaceNet_TFLite',
        'dimension': embeddingVector.length, // 🟢 192 chiều
        'consent_status': hasConsent ? 'GRANTED' : 'PENDING',
        if (hasConsent) 'consented_by': widget.parentId,
        if (hasConsent) 'consented_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đăng ký thành công khuôn mặt cho ${widget.studentName}!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Lỗi: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Đăng ký mặt: ${widget.studentName}')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CameraPreview(_cameraController!),
                Container(
                  width: 250,
                  height: 320,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 3),
                    borderRadius: BorderRadius.circular(160),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Column(
              children: [
                Text(_statusText, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    onPressed: _isProcessing ? null : _captureAndSaveFace,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt, color: Colors.white),
                    label: Text(
                      _isProcessing ? 'ĐANG XỬ LÝ...' : 'CHỤP & ĐĂNG KÝ MẶT',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}