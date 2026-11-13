/// Khớp với users.role trong CSDL:
/// ADMIN | SCHOOL_MANAGER | TEACHER | DRIVER | PARENT
enum UserRole {
  admin,
  schoolManager,
  teacher,
  driver,
  parent,
}

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
        UserRole.admin => 'Quản trị viên',
        UserRole.schoolManager => 'Quản lý trường',
        UserRole.teacher => 'Giáo viên',
        UserRole.driver => 'Tài xế',
        UserRole.parent => 'Phụ huynh',
      };
}

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,
    this.avatarUrl,
  });
}