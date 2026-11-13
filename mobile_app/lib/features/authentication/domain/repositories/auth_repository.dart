import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser> login({
    required String email,
    required String password,
  });

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<AppUser?> getCurrentUser();

  Future<void> logout();
}