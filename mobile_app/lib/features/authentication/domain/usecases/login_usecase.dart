import '../../../../core/errors/failures.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AppUser> call({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty) {
      throw const AuthFailure('Email không được để trống');
    }
    if (!_emailRegex.hasMatch(cleanEmail)) {
      throw const AuthFailure('Email không hợp lệ');
    }
    if (password.isEmpty) {
      throw const AuthFailure('Mật khẩu không được để trống');
    }

    return repository.login(email: cleanEmail, password: password);
  }
}