import '../../data/models/parent_models.dart';
import 'package:mobile_app/features/alerts/data/models/absence_request_model.dart';

abstract class ParentRepository {
  Future<List<ChildInfo>> getMyChildren();
  Future<void> requestLinkStudent({
    required String studentCode,
    required String relationship,
  });
  Stream<List<TodayTrip>> watchChildToday(String studentId);
  Stream<GpsPoint?> watchBusLocation(String tripId);

  Future<ParentProfile> getMyProfile();
  Future<void> updateMyProfile({
    required String fullName,
    String? phone,
    String? address,
    String? occupation,
  });
  Future<FaceConsent> getFaceConsent(String studentId);
  Future<void> setFaceConsent({required String studentId, required bool granted});
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<List<AbsenceRequestModel>> getAbsenceRequests(String studentId);
  /// Trả về số buổi đã tạo (mỗi ngày/buổi là một dòng trong bảng absences).
  Future<int> createAbsenceRequest({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
    required String tripType, // MORNING | AFTERNOON | BOTH
  });

  /// Tuyến xe, điểm đón và trạng thái đăng ký khuôn mặt của một học sinh.
  Future<ChildProfileInfo> getChildProfileInfo(String studentId);

  /// Bật/tắt thông báo thường cho tất cả con đã liên kết.
  Future<void> setNotificationsEnabled(bool enabled);

  /// Hủy/xóa yêu cầu liên kết đang chờ duyệt hoặc đã bị từ chối.
  Future<void> cancelLinkRequest(String studentId);
}
