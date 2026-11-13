import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/profile/data/models/user_profile_model.dart';

class ProfileRemoteDataSource {
  static const String avatarBucket = 'avatars';

  final SupabaseClient client;

  const ProfileRemoteDataSource(this.client);

  String get _uid {
    final id = client.auth.currentUser?.id;
    if (id == null) throw AuthException('Chưa đăng nhập');
    return id;
  }

  // =========================================================
  // HỒ SƠ
  // =========================================================

  Future<UserProfileModel> getProfile() async {
    final row = await client
        .from('users')
        .select('user_id, full_name, email, avatar_url')
        .eq('user_id', _uid)
        .single();

    return UserProfileModel.fromJson(row);
  }

  Future<void> updateFullName(String fullName) async {
    await client
        .from('users')
        .update({'full_name': fullName}).eq('user_id', _uid);

    // Đồng bộ sang metadata của tài khoản (không bắt buộc, lỗi thì bỏ qua)
    try {
      await client.auth.updateUser(
        UserAttributes(data: {'full_name': fullName}),
      );
    } catch (_) {}
  }

  // =========================================================
  // EMAIL & MẬT KHẨU
  // =========================================================

  Future<void> requestEmailChange(String newEmail) async {
    await client.auth.updateUser(UserAttributes(email: newEmail));
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = client.auth.currentUser?.email;
    if (email == null) throw AuthException('Chưa đăng nhập');

    // Xác minh mật khẩu hiện tại bằng cách đăng nhập lại
    await client.auth.signInWithPassword(
      email: email,
      password: currentPassword,
    );

    await client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // =========================================================
  // ẢNH ĐẠI DIỆN
  // =========================================================

  Future<String> uploadAvatar(Uint8List bytes, String contentType) async {
    final uid = _uid;
    final path = '$uid/avatar';

    await client.storage.from(avatarBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    // Thêm tham số v để app không hiển thị ảnh cũ đã được cache
    final publicUrl = client.storage.from(avatarBucket).getPublicUrl(path);
    final url = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';

    await client.from('users').update({'avatar_url': url}).eq('user_id', uid);

    return url;
  }

  Future<void> removeAvatar() async {
    final uid = _uid;

    await client.storage.from(avatarBucket).remove(['$uid/avatar']);
    await client.from('users').update({'avatar_url': null}).eq('user_id', uid);
  }
  Future<void> updatePhone(String? phone) async {
  final uid = client.auth.currentUser!.id;
  await client
      .from('users')
      .update({'phone': phone})
      .eq('user_id', uid);
}
}