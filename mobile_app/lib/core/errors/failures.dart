/// Lỗi xác thực có thông báo tiếng Việt để hiện thẳng lên giao diện.
/// toString() trả về đúng nội dung, nên `e.toString()` trong UI là đủ.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}