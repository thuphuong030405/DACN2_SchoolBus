/// Lỗi đã được dịch sang tiếng Việt, có thể hiện thẳng cho người dùng.
class ProfileException implements Exception {
  final String message;

  const ProfileException(this.message);

  @override
  String toString() => message;
}