import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/student_api.dart';
import '../../data/models/student_model.dart';

String friendlyStudentError(Object e) {
  final t = e.toString();
  const map = {
    'NOT_ALLOWED': 'Bạn không có quyền thực hiện thao tác này với học sinh này',
    'INVALID_NAME': 'Họ tên không hợp lệ (không được để trống, tối đa 150 ký tự)',
    'INVALID_DOB': 'Ngày sinh không hợp lệ',
    'INVALID_GENDER': 'Giới tính không hợp lệ',
    'INVALID_CLASS': 'Tên lớp quá dài (tối đa 50 ký tự)',
    'CONSENT_REQUIRED': 'Bạn cần đồng ý sử dụng khuôn mặt trước khi đăng ký',
    'INVALID_EMBEDDING': 'Dữ liệu khuôn mặt không hợp lệ, vui lòng chụp lại',
    'INVALID_SAMPLE_COUNT': 'Số ảnh mẫu không hợp lệ',
    'INVALID_MODEL': 'Mô hình nhận diện không hợp lệ',
    'INVALID_DIMENSION': 'Kích thước vector không hợp lệ',
    'INVALID_AVATAR': 'Ảnh đại diện không hợp lệ',
  };
  for (final entry in map.entries) {
    if (t.contains(entry.key)) return entry.value;
  }
  return 'Có lỗi xảy ra: $e';
}

final childDetailProvider = FutureProvider.autoDispose.family<ChildDetail, String>(
  (ref, studentId) => StudentManageApi.getDetail(studentId),
);

final childFaceStatusProvider = FutureProvider.autoDispose.family<FaceStatus, String>(
  (ref, studentId) => StudentManageApi.faceStatus(studentId),
);