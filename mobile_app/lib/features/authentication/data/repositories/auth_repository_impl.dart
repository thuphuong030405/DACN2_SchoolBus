import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      await remoteDataSource.login(email: email, password: password);

      final profile = await _loadProfileOrSignOut();
      if (profile == null) {
        throw const AuthFailure('Không tìm thấy thông tin tài khoản');
      }
      return profile;
    });
  }

  @override
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) {
    return _guard(() {
      return remoteDataSource.register(
        fullName: fullName,
        email: email,
        password: password,
      );
    });
  }

  @override
  Future<AppUser?> getCurrentUser() {
    return _guard(_loadProfileOrSignOut);
  }

  @override
  Future<void> logout() {
    return _guard(remoteDataSource.logout);
  }

  // ---------------------------------------------------------------------

  /// Đọc hồ sơ + kiểm tra tài khoản còn hoạt động.
  /// Có lỗi thì đăng xuất luôn, tránh trạng thái "đã đăng nhập Supabase
  /// nhưng không có hồ sơ hợp lệ".
  Future<AppUser?> _loadProfileOrSignOut() async {
    try {
      final profile = await remoteDataSource.getCurrentProfile();
      if (profile == null) return null; // chưa đăng nhập

      if (profile['is_active'] != true) {
        throw const AuthFailure(
          'Tài khoản đã bị khóa. Vui lòng liên hệ nhà trường.',
        );
      }
      return AppUserModel.fromMap(profile);
    } catch (_) {
      try {
        await remoteDataSource.logout();
      } catch (_) {}
      rethrow;
    }
  }

  /// Đổi mọi lỗi kỹ thuật thành AuthFailure có thông báo tiếng Việt
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(_authMessage(e));
    } on PostgrestException {
      throw const AuthFailure(
        'Không đọc được dữ liệu tài khoản. Kiểm tra quyền truy cập (RLS) và thử lại.',
      );
    } on SocketException {
      throw const AuthFailure('Không có kết nối mạng. Vui lòng thử lại.');
    } catch (_) {
      throw const AuthFailure('Có lỗi xảy ra, vui lòng thử lại.');
    }
  }

  String _authMessage(AuthException e) {
    final msg = e.message.toLowerCase();
    final code = e.code ?? '';

    if (e is AuthRetryableFetchException) {
      return 'Không thể kết nối. Kiểm tra mạng và thử lại.';
    }
    if (code == 'invalid_credentials' ||
        msg.contains('invalid login credentials')) {
      return 'Email hoặc mật khẩu không đúng.';
    }
    if (code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
      return 'Email chưa được xác nhận. Hãy kiểm tra hộp thư của bạn.';
    }
    if (code == 'user_already_exists' || msg.contains('already registered')) {
      return 'Email này đã được đăng ký.';
    }
    if (msg.contains('database error saving new user')) {
      return 'Không tạo được hồ sơ tài khoản. Email có thể đã tồn tại.';
    }
    if (code == 'weak_password' || msg.contains('password should')) {
      return 'Mật khẩu quá yếu. Hãy dùng mật khẩu dài và khó đoán hơn.';
    }
    if (code.contains('rate_limit') || msg.contains('rate limit')) {
      return 'Thao tác quá nhanh. Vui lòng thử lại sau ít phút.';
    }
    return 'Xác thực thất bại, vui lòng thử lại.';
  }
}