import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/failures.dart';

class AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSource(this.client);

  static const _usersTable = 'users';
  static const _profileColumns =
      'user_id, username, full_name, email, phone, avatar_url, role, is_active';

  // LOGIN
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const AuthFailure('Không thể đăng nhập');
    }
    return user;
  }

  // REGISTER
  // Chỉ tạo tài khoản trong Supabase Auth. Dòng trong public.users và
  // public.parents do trigger handle_new_user (file 005_auth_trigger.sql) tạo,
  // vì RLS không cho app tự INSERT vào bảng users.
  // Trả về true nếu đã đăng nhập luôn (tắt xác nhận email).
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final user = response.user;
    if (user == null) {
      throw const AuthFailure('Không thể tạo tài khoản');
    }

    // Khi bật xác nhận email, email đã tồn tại sẽ KHÔNG báo lỗi mà trả về
    // user có danh sách identities rỗng.
    if (user.identities != null && user.identities!.isEmpty) {
      throw const AuthFailure('Email này đã được đăng ký');
    }

    return response.session != null;
  }

  // LẤY HỒ SƠ từ bảng public.users (RLS: chỉ đọc được dòng của chính mình)
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final result = await client
        .from(_usersTable)
        .select(_profileColumns)
        .eq('user_id', user.id)
        .maybeSingle();

    if (result == null) {
      throw const AuthFailure(
        'Tài khoản chưa có hồ sơ trong hệ thống. Vui lòng liên hệ nhà trường.',
      );
    }

    return {
      ...result,
      'email': user.email ?? result['email'] ?? '',
    };
  }

  // LOGOUT
  Future<void> logout() async {
    await client.auth.signOut();
  }
}