import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  /// Trả về true nếu đã đăng nhập luôn sau khi đăng ký
  /// (false = cần xác nhận email trước).
  Future<bool> call({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final cleanName = fullName.trim();
    final cleanEmail = email.trim();

    if (cleanName.isEmpty) {
      throw const AuthFailure('Họ tên không được để trống');
    }
    // users.full_name là VARCHAR(150)
    if (cleanName.length > 150) {
      throw const AuthFailure('Họ tên tối đa 150 ký tự');
    }
    if (cleanEmail.isEmpty) {
      throw const AuthFailure('Email không được để trống');
    }
    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw const AuthFailure('Email không hợp lệ');
    }
    if (password.length < 8) {
      throw const AuthFailure('Mật khẩu phải có ít nhất 8 ký tự');
    }

    return repository.register(
      fullName: cleanName,
      email: cleanEmail,
      password: password,
    );
  }
}