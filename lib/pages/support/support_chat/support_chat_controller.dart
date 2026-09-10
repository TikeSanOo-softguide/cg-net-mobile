import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isMine,
    required this.sentAt,
  });

  final String text;
  final bool isMine;
  final DateTime sentAt;
}

class SupportChatController extends StateNotifier<List<ChatMessage>> {
  SupportChatController()
      : super([
          ChatMessage(
            text: 'Hello! I am CG-NET Support AI. How can I help you today?',
            isMine: false,
            sentAt: DateTime.now().subtract(const Duration(minutes: 2)),
          ),
        ]);

  void send(String text) {
    final now = DateTime.now();
    state = [
      ...state,
      ChatMessage(text: text, isMine: true, sentAt: now),
      ChatMessage(
        text:
            'Thanks for your message. Our support team will follow up shortly.',
        isMine: false,
        sentAt: now.add(const Duration(seconds: 1)),
      ),
    ];
  }
}

final supportChatControllerProvider =
    StateNotifierProvider<SupportChatController, List<ChatMessage>>((ref) {
  return SupportChatController();
});
