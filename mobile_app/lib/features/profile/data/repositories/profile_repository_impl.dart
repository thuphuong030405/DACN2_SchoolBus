import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:mobile_app/features/profile/domain/entities/user_profile.dart';
import 'package:mobile_app/features/profile/domain/profile_exception.dart';
import 'package:mobile_app/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;

  const ProfileRepositoryImpl(this.remote);

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw _toProfileException(e);
    }
  }

  @override
  Future<UserProfile> getProfile() => _guard(remote.getProfile);

  @override
  Future<void> updateFullName(String fullName) =>
      _guard(() => remote.updateFullName(fullName));

  @override
  Future<void> updatePhone(String? phone) =>
      _guard(() => remote.updatePhone(phone));

  @override
  Future<void> requestEmailChange(String newEmail) =>
      _guard(() => remote.requestEmailChange(newEmail));

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _guard(
        () => remote.changePassword(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );

  @override
  Future<String> uploadAvatar(Uint8List bytes, String contentType) =>
      _guard(() => remote.uploadAvatar(bytes, contentType));

  @override
  Future<void> removeAvatar() => _guard(remote.removeAvatar);

  // =========================================================
  // DỊCH LỖI SANG TIẾNG VIỆT
  // =========================================================

  ProfileException _toProfileException(Object e) {
    if (e is ProfileException) return e;

    if (e is AuthException) {
      final m = e.message.toLowerCase();

      if (m.contains('invalid login credentials')) {
        return const ProfileException('Mật khẩu hiện tại không đúng.');
      }
      if (m.contains('different from the old password')) {
        return const ProfileException(
          'Mật khẩu mới phải khác mật khẩu hiện tại.',
        );
      }
      if (m.contains('at least')) {
        return const ProfileException('Mật khẩu mới quá ngắn.');
      }
      if (m.contains('weak') || m.contains('pwned')) {
        return const ProfileException(
          'Mật khẩu mới quá dễ đoán, hãy chọn mật khẩu khác.',
        );
      }
      if (m.contains('already') && m.contains('registered')) {
        return const ProfileException('Email này đã được sử dụng.');
      }
      if (m.contains('rate limit') || m.contains('too many')) {
        return const ProfileException(
          'Bạn thao tác quá nhanh, vui lòng thử lại sau ít phút.',
        );
      }
      if (m.contains('chưa đăng nhập')) {
        return const ProfileException(
          'Phiên đăng nhập đã hết, hãy đăng nhập lại.',
        );
      }
      return ProfileException(e.message);
    }

    if (e is StorageException) {
      return ProfileException('Không tải được ảnh lên: ${e.message}');
    }

    if (e is PostgrestException) {
      if (e.code == '42501') {
        return const ProfileException(
          'Bạn không có quyền thực hiện thao tác này.',
        );
      }
      if (e.code == '23505') {
        return const ProfileException('Thông tin này đã tồn tại.');
      }
      return ProfileException(e.message);
    }

    final text = e.toString();
    if (text.contains('SocketException') ||
        text.contains('ClientException') ||
        text.contains('Failed host lookup')) {
      return const ProfileException('Không có kết nối mạng.');
    }

    return const ProfileException('Có lỗi xảy ra, vui lòng thử lại.');
  }
}