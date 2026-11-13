import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';

import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';

// Supabase Remote Data Source
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(Supabase.instance.client);
});

// Repository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// Use Cases
final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final logoutUseCaseProvider = Provider<LogoutUseCase>((ref) {
  return LogoutUseCase(ref.watch(authRepositoryProvider));
});

/// Lắng nghe đăng nhập / đăng xuất / refresh token của Supabase.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// Current User: tự chạy lại mỗi khi trạng thái đăng nhập thay đổi,
/// nên AuthGate sẽ tự chuyển sang giao diện theo role ngay sau khi login.
final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  // Phụ thuộc vào stream để provider được dựng lại khi auth thay đổi
  ref.watch(authStateChangesProvider);

  // Chưa có phiên đăng nhập -> chắc chắn chưa login, khỏi gọi repository
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    debugPrint('currentUserProvider: no session');
    return null;
  }

  final user = await ref.watch(authRepositoryProvider).getCurrentUser();
  debugPrint('currentUserProvider: user = $user');
  return user;
});