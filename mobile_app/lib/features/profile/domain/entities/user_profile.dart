class UserProfile {
  final String userId;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;

  const UserProfile({
    required this.userId,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
  });

  bool get hasAvatar => avatarUrl != null && avatarUrl!.isNotEmpty;

  bool get hasPhone => phone != null && phone!.trim().isNotEmpty;
}