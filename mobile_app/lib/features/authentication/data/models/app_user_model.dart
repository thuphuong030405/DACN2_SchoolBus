import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.role,
    super.phone,
    super.avatarUrl,
  });

  /// [map] là một dòng của bảng public.users
  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['user_id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      role: _parseRole(map['role'] as String?),
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  static UserRole _parseRole(String? value) {
    return switch ((value ?? '').toUpperCase()) {
      'ADMIN' => UserRole.admin,
      'SCHOOL_MANAGER' => UserRole.schoolManager,
      'TEACHER' => UserRole.teacher,
      'DRIVER' => UserRole.driver,
      _ => UserRole.parent, // giá trị lạ -> quyền thấp nhất
    };
  }
}