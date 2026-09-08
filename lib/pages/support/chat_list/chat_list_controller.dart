import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model/user_model.dart';

class ChatListController
    extends StateNotifier<AsyncValue<List<ChatThreadModel>>> {
  ChatListController() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    state = AsyncValue.data([
      ChatThreadModel(
        id: 'c1',
        title: 'CG Net Support',
        lastMessage: 'How can we help you today?',
        updatedAt: DateTime.now().subtract(const Duration(minutes: 20)),
        unreadCount: 1,
      ),
      ChatThreadModel(
        id: 'c2',
        title: 'Billing desk',
        lastMessage: 'Your payment was received. Thank you!',
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }
}

final chatListControllerProvider = StateNotifierProvider<ChatListController,
    AsyncValue<List<ChatThreadModel>>>((ref) {
  return ChatListController();
});
