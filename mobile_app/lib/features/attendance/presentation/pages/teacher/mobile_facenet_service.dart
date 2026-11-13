import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class MobileFaceNetService {
  static const String modelAsset = 'assets/mobilefacenet.tflite';
  static const int inputSize = 112;

  Interpreter? _interpreter;
  Future<void>? _loading;
  int _outputDim = 192;

  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );

  /// Nạp model. Nếu lỗi sẽ ném exception để thấy lỗi thật (không nuốt lỗi nữa).
  Future<void> loadModel() {
    if (_interpreter != null) return Future.value();
    return _loading ??= _load().catchError((e) {
      _loading = null; // cho phép thử lại lần sau
      throw e;
    });
  }

  Future<void> _load() async {
    final interpreter = await Interpreter.fromAsset(modelAsset);
    final inShape = interpreter.getInputTensor(0).shape;
    final outShape = interpreter.getOutputTensor(0).shape;
    debugPrint('🟢 MobileFaceNet loaded. IN: $inShape '
        '(${interpreter.getInputTensor(0).type}) OUT: $outShape');
    _outputDim = outShape.last;
    _interpreter = interpreter;
  }

  /// Tham số [face] giữ lại cho tương thích, KHÔNG dùng vì tọa độ của nó
  /// thuộc khung hình khác. Hàm tự phát hiện lại mặt trên file ảnh.
  /// Trả về [] nếu không thấy mặt. Ném exception nếu model lỗi.
  Future<List<double>> extractEmbedding(String imagePath, [Face? face]) async {
    await loadModel();
    final interpreter = _interpreter!;

    // 1. Đọc ảnh và xoay đúng hướng (EXIF), lưu file tạm đã "nướng" hướng xoay
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return [];
    final baked = img.bakeOrientation(decoded);

    final tmpPath = '$imagePath.baked.jpg';
    await File(tmpPath).writeAsBytes(img.encodeJpg(baked, quality: 95));

    try {
      // 2. Phát hiện mặt trên đúng ảnh đã xoay -> tọa độ chắc chắn khớp
      final faces =
          await _detector.processImage(InputImage.fromFilePath(tmpPath));
      if (faces.isEmpty) return [];

      // chọn khuôn mặt lớn nhất
      faces.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final rect = faces.first.boundingBox;

      // 3. Crop (mở rộng nhẹ 10% rồi giới hạn trong khung ảnh)
      final padX = rect.width * 0.10;
      final padY = rect.height * 0.10;
      final x = (rect.left - padX).toInt().clamp(0, baked.width - 1);
      final y = (rect.top - padY).toInt().clamp(0, baked.height - 1);
      final w = (rect.width + 2 * padX).toInt().clamp(1, baked.width - x);
      final h = (rect.height + 2 * padY).toInt().clamp(1, baked.height - y);

      final cropped = img.copyCrop(baked, x: x, y: y, width: w, height: h);
      final resized =
          img.copyResize(cropped, width: inputSize, height: inputSize);

      // 4. Tensor đầu vào [1,112,112,3], chuẩn hóa về [-1, 1]
      final input = [
        List.generate(
          inputSize,
          (yy) => List.generate(inputSize, (xx) {
            final p = resized.getPixel(xx, yy);
            return [
              (p.r - 127.5) / 127.5,
              (p.g - 127.5) / 127.5,
              (p.b - 127.5) / 127.5,
            ];
          }),
        )
      ];

      // 5. Chạy model, đầu ra lấy theo shape thật của model
      final output = List.filled(_outputDim, 0.0).reshape([1, _outputDim]);
      interpreter.run(input, output);

      return _l2Normalize(List<double>.from(output[0]));
    } finally {
      try {
        await File(tmpPath).delete();
      } catch (_) {}
    }
  }

  List<double> _l2Normalize(List<double> v) {
    double sum = 0;
    for (final e in v) {
      sum += e * e;
    }
    final norm = sqrt(sum);
    if (norm == 0) return v;
    return v.map((e) => e / norm).toList();
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
    _loading = null;
    _detector.close();
  }
}