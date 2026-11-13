enum ChatRole { user, model }

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final DateTime createdAt;

  /// Tin chào mở đầu: hiển thị trong app nhưng không gửi lên Gemini.
  final bool isWelcome;

  ChatMessage({
    required this.role,
    required this.text,
    this.isWelcome = false,
    DateTime? createdAt,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now();
}