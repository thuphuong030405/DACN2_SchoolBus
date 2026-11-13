import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/features/chatbot/domain/chat_message.dart';

class ChatException implements Exception {
  final String message;
  const ChatException(this.message);

  @override
  String toString() => message;
}

/// Gọi Edge Function `gemini-chat` của Supabase.
/// API key Gemini nằm trên server, app không bao giờ giữ key.
class ChatRemoteDataSource {
  Future<String> ask(
    List<ChatMessage> history, {
    String? userRole,
  }) async {
    try {
      final response = await Supabase.instance.client.functions
          .invoke(
            'gemini-chat',
            body: {
              'role': userRole,
              'messages': history
                  .map((m) => {
                        'role': m.role == ChatRole.user ? 'user' : 'model',
                        'text': m.text,
                      })
                  .toList(),
            },
          )
          .timeout(const Duration(seconds: 45));

      final data = response.data;
      if (data is Map && data['reply'] is String) {
        return (data['reply'] as String).trim();
      }

      debugPrint('[chatbot] Phản hồi không hợp lệ: $data');
      throw const ChatException('Phản hồi từ trợ lý không hợp lệ.');
    } on ChatException {
      rethrow;
    } on FunctionException catch (e) {
      debugPrint('[chatbot] gemini-chat lỗi HTTP ${e.status}: ${e.details}');
      throw ChatException(_functionErrorMessage(e));
    } on TimeoutException {
      debugPrint('[chatbot] Hết 45 giây mà gemini-chat chưa trả lời');
      throw const ChatException('Trợ lý phản hồi quá lâu, vui lòng thử lại.');
    } catch (e) {
      debugPrint('[chatbot] Lỗi không xác định: $e');
      throw const ChatException('Không thể kết nối. Kiểm tra mạng và thử lại.');
    }
  }

  String _functionErrorMessage(FunctionException e) {
    if (e.status == 401) {
      return 'Phiên đăng nhập đã hết, hãy đăng nhập lại.';
    }
    if (e.status == 404) {
      return 'Chưa triển khai hàm gemini-chat trên Supabase.';
    }

    // Hàm trả về {"error": "..."}: hiện đúng nội dung đó để biết nguyên nhân thật
    // (khi bật GEMINI_DEBUG, nội dung này là lỗi nguyên văn của Gemini).
    final details = e.details;
    final serverMessage =
        (details is Map && details['error'] is String)
            ? details['error'] as String
            : null;

    if (e.status == 429) {
      return serverMessage ??
          'Trợ lý đang quá tải, vui lòng thử lại sau ít phút.';
    }
    return serverMessage ?? 'Trợ lý đang gặp sự cố, vui lòng thử lại.';
  }
}

final chatRemoteDataSourceProvider = Provider<ChatRemoteDataSource>((ref) {
  return ChatRemoteDataSource();
});

// -------------------------------------------------------------------------

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final String? error;

  const ChatState({
    required this.messages,
    this.isSending = false,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatController extends Notifier<ChatState> {
  static const String _welcomeText =
      'Xin chào! Mình là trợ lý AI của Bus An Toàn. '
      'Mình có thể giải đáp về đưa đón học sinh, điểm danh, an toàn trên xe '
      'và cách dùng ứng dụng. Bạn cần giúp gì?';

  String? _userRole;

  ChatState _initial() {
    return ChatState(
      messages: [
        ChatMessage(
          role: ChatRole.model,
          text: _welcomeText,
          isWelcome: true,
        ),
      ],
    );
  }

  @override
  ChatState build() => _initial();

  Future<void> send(String text, {String? userRole}) async {
    final content = text.trim();
    if (content.isEmpty || state.isSending) return;

    _userRole = userRole ?? _userRole;

    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessage(role: ChatRole.user, text: content),
      ],
      isSending: true,
      clearError: true,
    );

    await _requestReply();
  }

  /// Gửi lại câu hỏi gần nhất sau khi gặp lỗi (không thêm tin trùng).
  Future<void> retry() async {
    if (state.isSending) return;
    state = state.copyWith(isSending: true, clearError: true);
    await _requestReply();
  }

  void clear() {
    if (state.isSending) return;
    state = _initial();
  }

  Future<void> _requestReply() async {
    try {
      final history = state.messages.where((m) => !m.isWelcome).toList();

      final reply = await ref
          .read(chatRemoteDataSourceProvider)
          .ask(history, userRole: _userRole);

      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(role: ChatRole.model, text: _clean(reply)),
        ],
        isSending: false,
      );
    } on ChatException catch (e) {
      state = state.copyWith(isSending: false, error: e.message);
    } catch (e) {
      debugPrint('[chatbot] Lỗi khi xử lý câu trả lời: $e');
      state = state.copyWith(
        isSending: false,
        error: 'Có lỗi xảy ra, vui lòng thử lại.',
      );
    }
  }

  /// Gemini đôi khi vẫn trả markdown; làm sạch để hiển thị gọn trong bong bóng chat.
  String _clean(String text) {
    var t = text.replaceAll('**', '').replaceAll('__', '');
    t = t.replaceAllMapped(
      RegExp(r'^[ \t]*[\*\-][ \t]+', multiLine: true),
      (_) => '• ',
    );
    t = t.replaceAll(RegExp(r'^#{1,6}[ \t]*', multiLine: true), '');
    return t.trim();
  }
}

final chatControllerProvider =
    NotifierProvider<ChatController, ChatState>(ChatController.new);