import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:mobile_app/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mobile_app/features/profile/domain/entities/user_profile.dart';
import 'package:mobile_app/features/profile/domain/repositories/profile_repository.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>(
  (ref) => ProfileRemoteDataSource(Supabase.instance.client),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.watch(profileRemoteDataSourceProvider)),
);

/// Hồ sơ của tài khoản đang đăng nhập (tên, email, ảnh đại diện).
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});