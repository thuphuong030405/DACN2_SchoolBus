import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class FaceEmbeddingHelper {
  
  /// 1. Chuyển Vector List<double> -> Chuỗi Hex PostgreSQL BYTEA (\x...)
  static String float32ListToHexBytea(List<double> list) {
    final floatList = Float32List.fromList(list);
    final uint8List = floatList.buffer.asUint8List();
    final hexString = uint8List.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return r'\x' + hexString;
  }

  /// 2. Giải mã dữ liệu BYTEA từ Supabase -> List<double> (Float32)
  static List<double> bytesToFloat32List(dynamic rawData) {
    if (rawData == null) return [];

    try {
      Uint8List bytes;

      if (rawData is String) {
        String hexStr = rawData.startsWith(r'\x') ? rawData.substring(2) : rawData;
        List<int> intList = [];
        for (int i = 0; i < hexStr.length; i += 2) {
          intList.add(int.parse(hexStr.substring(i, i + 2), radix: 16));
        }
        bytes = Uint8List.fromList(intList);
      } else if (rawData is List) {
        bytes = Uint8List.fromList(List<int>.from(rawData));
      } else {
        return [];
      }

      if (bytes.isEmpty || bytes.length < 4) return [];

      final ByteData byteData = ByteData.sublistView(bytes);
      final List<double> result = [];
      for (int i = 0; i < byteData.lengthInBytes - (byteData.lengthInBytes % 4); i += 4) {
        result.add(byteData.getFloat32(i, Endian.host));
      }
      return result;
    } catch (e) {
      debugPrint('Lỗi giải mã bytesToFloat32List: $e');
      return [];
    }
  }

  /// 3. Tính Cosine Similarity chuẩn toán học
  static double calculateCosineSimilarity(List<double> v1, List<double> v2) {
    if (v1.isEmpty || v2.isEmpty || v1.length != v2.length) return 0.0;
    
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      normA += v1[i] * v1[i];
      normB += v2[i] * v2[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;

    final double denominator = sqrt(normA) * sqrt(normB);
    if (denominator == 0.0) return 0.0;

    return dotProduct / denominator;
  }
}