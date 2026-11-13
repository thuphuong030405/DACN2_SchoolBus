import 'dart:typed_data';

import 'package:mobile_app/features/profile/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getProfile();

  Future<void> updateFullName(String fullName);

  /// Gửi yêu cầu đổi email. Email chỉ đổi thật sự sau khi người dùng xác nhận qua thư.
  Future<void> requestEmailChange(String newEmail);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Tải ảnh đại diện lên và trả về đường dẫn ảnh.
  Future<String> uploadAvatar(Uint8List bytes, String contentType);

  Future<void> removeAvatar();

  Future<void> updatePhone(String? phone);
}