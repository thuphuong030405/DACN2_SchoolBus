import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Không tìm thấy đúng 1 khuôn mặt trong ảnh.
class FaceNotDetectedException implements Exception {
  FaceNotDetectedException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// HỢP ĐỒNG với phần AI (điểm danh):
///  - Cùng MỘT mô hình + cùng cách tiền xử lý cho cả ĐĂNG KÝ (ở đây) và NHẬN DIỆN (app điểm danh),
///    nếu không vector sẽ không so khớp được.
///  - [embed] nhận ảnh chụp, tự phát hiện + cắt khuôn mặt, trả về vector đã chuẩn hóa L2.
///  - [modelName] là tên mô hình; app điểm danh chỉ nên tải vector có model_name trùng mô hình của nó.
abstract class FaceEmbedder {
  String get modelName;

  /// true = vector giả để thử luồng, KHÔNG dùng để điểm danh thật.
  bool get isFake;

  /// Ném [FaceNotDetectedException] nếu không có khuôn mặt (hoặc có nhiều hơn 1).
  Future<Float32List> embed(File image);
}

/// CHỈ ĐỂ THỬ NGHIỆM: sinh vector giả (cùng ảnh -> cùng vector) để test toàn bộ luồng
/// chụp -> lưu -> hiển thị trạng thái khi chưa nối mô hình thật.
class DevFakeFaceEmbedder implements FaceEmbedder {
  const DevFakeFaceEmbedder();

  @override
  String get modelName => 'DEV-FAKE';

  @override
  bool get isFake => true;

  @override
  Future<Float32List> embed(File image) async {
    final bytes = await image.readAsBytes();
    if (bytes.length < 1024) {
      throw FaceNotDetectedException('Ảnh bị lỗi hoặc quá nhỏ, vui lòng chụp lại');
    }
    var h = 0x811C9DC5; // FNV-1a trên các byte lấy mẫu
    for (var i = 0; i < bytes.length; i += 97) {
      h ^= bytes[i];
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    final rnd = math.Random(h);
    final v = Float32List(128);
    var sum = 0.0;
    for (var i = 0; i < v.length; i++) {
      final x = rnd.nextDouble() * 2 - 1;
      v[i] = x;
      sum += x * x;
    }
    final norm = math.sqrt(sum);
    for (var i = 0; i < v.length; i++) {
      v[i] = v[i] / norm;
    }
    return v;
  }
}

/// ===== NỐI MÔ HÌNH THẬT Ở ĐÂY =====
/// Khi phần AI điểm danh đã có service tạo vector (MobileFaceNet/ArcFace TFLite...),
/// tạo một class implements [FaceEmbedder] gọi vào service đó rồi đổi provider bên dưới, ví dụ:
///   final faceEmbedderProvider = Provider<FaceEmbedder>((ref) => TfliteFaceEmbedder(...));
final faceEmbedderProvider =
    Provider<FaceEmbedder>((ref) => const DevFakeFaceEmbedder());