import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.isMine});

  final String text;
  final bool isMine;
}

class ChatDetailController extends StateNotifier<List<ChatMessage>> {
  ChatDetailController(this.chatId)
      : super(const [
          ChatMessage(text: 'Hello! How can we help?', isMine: false),
        ]);

  final String chatId;

  void send(String text) {
    state = [
      ...state,
      ChatMessage(text: text, isMine: true),
    ];
  }
}

final chatDetailControllerProvider = StateNotifierProvider.family<
    ChatDetailController, List<ChatMessage>, String>((ref, id) {
  return ChatDetailController(id);
});
