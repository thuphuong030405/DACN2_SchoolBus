import 'dart:io';
import 'dart:typed_data';
import 'package:mobile_app/core/services/storage_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentManageApi {
  StudentManageApi._();
  static SupabaseClient get _db => Supabase.instance.client;
  static const consentVersion = 'v1.0';

  static Future<ChildDetail> getDetail(String studentId) async {
    final rows = await _db.rpc('get_my_child_detail', params: {'p_student_id': studentId});
    final list = rows as List;
    if (list.isEmpty) throw Exception('NOT_ALLOWED');
    return ChildDetail.fromMap(list.first as Map<String, dynamic>);
  }

  static Future<void> updateChild({
    required String studentId,
    required String fullName,
    required DateTime dateOfBirth,
    required String? gender,
    required String? className,
  }) async {
    String two(int n) => n.toString().padLeft(2, '0');
    await _db.rpc('update_my_child', params: {
      'p_student_id': studentId,
      'p_full_name': fullName.trim(),
      'p_date_of_birth': '${dateOfBirth.year.toString().padLeft(4, '0')}-${two(dateOfBirth.month)}-${two(dateOfBirth.day)}',
      'p_gender': gender,
      'p_class_name': className?.trim(),
    });
  }

  static Future<FaceStatus> faceStatus(String studentId) async {
    final rows = await _db.rpc('get_child_face_status', params: {'p_student_id': studentId});
    final list = rows as List;
    return FaceStatus.fromMap(list.isEmpty ? null : list.first as Map<String, dynamic>);
  }

  static Future<void> setConsent(String studentId, bool granted) async {
    await _db.rpc('set_face_consent', params: {
      'p_student_id': studentId,
      'p_granted': granted,
      'p_version': consentVersion,
    });
  }

  static Future<int> registerFace({
    required String studentId,
    required String modelName,
    required List<Float32List> vectors,
    required List<String> poses,
  }) async {
    final res = await _db.rpc('register_face', params: {
      'p_student_id': studentId,
      'p_model_name': modelName,
      'p_dimension': vectors.first.length,
      'p_embeddings': vectors.map(_toHex).toList(),
      'p_poses': poses,
    });
    return (res as num).toInt();
  }

  // ------------------------------------------------------------ ảnh đại diện
  // Ảnh đại diện là ẢNH RIÊNG, không liên quan đến dữ liệu khuôn mặt (vector).

  /// Tải ảnh lên bucket 'avatars' rồi lưu đường dẫn vào hồ sơ học sinh.
  /// [previousUrl]: ảnh cũ, sẽ được xóa khỏi storage sau khi đổi thành công (không để file mồ côi).
  static Future<String> setAvatar({
    required String studentId,
    required File file,
    String? previousUrl,
  }) async {
    final url = await StorageService.uploadAvatar(
      file: file,
      folder: 'students',
      id: studentId,
    );
    await _db.rpc('update_child_avatar', params: {
      'p_student_id': studentId,
      'p_avatar_url': url,
    });
    await _removeObject(previousUrl);
    return url;
  }

  /// Gỡ ảnh đại diện (về lại chữ cái đầu tên).
  static Future<void> removeAvatar({
    required String studentId,
    required String? currentUrl,
  }) async {
    await _db.rpc('update_child_avatar', params: {
      'p_student_id': studentId,
      'p_avatar_url': null,
    });
    await _removeObject(currentUrl);
  }

  /// Xóa file trong bucket từ đường dẫn công khai; lỗi thì bỏ qua (không chặn người dùng).
  static Future<void> _removeObject(String? url) async {
    if (url == null) return;
    const marker = '/avatars/';
    final i = url.indexOf(marker);
    if (i < 0) return;
    final path = Uri.decodeComponent(url.substring(i + marker.length).split('?').first);
    try {
      await _db.storage.from('avatars').remove([path]);
    } catch (_) {}
  }

  static String _toHex(Float32List v) {
    final bd = ByteData(v.length * 4);
    for (var i = 0; i < v.length; i++) {
      bd.setFloat32(i * 4, v[i], Endian.little);
    }
    final sb = StringBuffer();
    for (final b in bd.buffer.asUint8List()) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}