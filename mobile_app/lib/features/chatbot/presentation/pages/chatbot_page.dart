import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mobile_app/features/chatbot/domain/chat_message.dart';
import 'package:mobile_app/features/chatbot/presentation/providers/chatbot_provider.dart';

/// Màn hình trò chuyện với trợ lý AI (Gemini qua Supabase Edge Function).
///
/// Mở bằng:
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => const ChatbotPage(userRole: 'giáo viên'),
///   ));
class ChatbotPage extends ConsumerStatefulWidget {
  /// Vai trò hiển thị cho AI biết (vd: 'phụ huynh', 'giáo viên', 'tài xế').
  final String? userRole;

  const ChatbotPage({super.key, this.userRole});

  @override
  ConsumerState<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends ConsumerState<ChatbotPage> {
  // ----- Bảng màu (đồng bộ toàn app) -----
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF1D4ED8);
  static const Color _bg = Color(0xFFF3F6FD);
  static const Color _line = Color(0xFFE2E8F5);
  static const Color _textDark = Color(0xFF10224A);
  static const Color _textMuted = Color(0xFF52628A);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _dangerBg = Color(0xFFFEE2E2);

  static const List<String> _suggestions = [
    'Cách điểm danh học sinh lên xe?',
    'Học sinh vắng thì xử lý thế nào?',
    'Cần làm gì khi xe gặp sự cố?',
    'Quy tắc an toàn trên xe đưa đón',
  ];

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? preset]) {
    final text = (preset ?? _inputController.text).trim();
    if (text.isEmpty) return;
    if (preset == null) _inputController.clear();

    ref
        .read(chatControllerProvider.notifier)
        .send(text, userRole: widget.userRole);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------------------------------------------------------------
  // Giao diện
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatControllerProvider);

    ref.listen<ChatState>(chatControllerProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.isSending != next.isSending ||
          prev?.error != next.error) {
        _scrollToBottom();
      }
    });

    final showSuggestions = chat.messages.length == 1 && !chat.isSending;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHeader(context, chat),
          Expanded(
            child: ListView(
              controller: _scrollController,
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              children: [
                for (final m in chat.messages) _bubble(m),
                if (showSuggestions) _buildSuggestions(),
                if (chat.isSending) _typingBubble(),
                if (chat.error != null) _errorCard(chat.error!),
              ],
            ),
          ),
          _buildInputBar(chat),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ChatState chat) {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x1FFFFFFF),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 18),
            child: Row(
              children: [
                _headerButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Quay lại',
                  onTap: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trợ lý AI',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Hỏi về đưa đón, điểm danh, an toàn xe',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _headerButton(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Xóa cuộc trò chuyện',
                  onTap: chat.isSending
                      ? null
                      : () => ref.read(chatControllerProvider.notifier).clear(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0x2EFFFFFF),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _botAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryDark],
        ),
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          size: 17, color: Colors.white),
    );
  }

  Widget _bubble(ChatMessage m) {
    final isUser = m.role == ChatRole.user;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _botAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? _primary : Colors.white,
                border: isUser ? null : Border.all(color: _line),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: SelectableText(
                m.text,
                style: TextStyle(
                  color: isUser ? Colors.white : _textDark,
                  fontSize: 14.5,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(left: 40, bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in _suggestions)
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _send(s),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFD3FB)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _typingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _botAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _line),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primary,
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Đang trả lời...',
                  style: TextStyle(color: _textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _dangerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: _danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () =>
                      ref.read(chatControllerProvider.notifier).retry(),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Thử lại',
                      style: TextStyle(
                        color: _danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatState chat) {
    final sending = chat.isSending;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Nhập câu hỏi của bạn...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6B7A99),
                          fontSize: 14,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: _bg,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: Material(
                      color: sending ? const Color(0xFF93B4F5) : _primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: sending ? null : _send,
                        child: const Icon(
                          Icons.send_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Trợ lý AI có thể sai. Hãy kiểm tra thông tin quan trọng.',
                style: TextStyle(color: _textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}