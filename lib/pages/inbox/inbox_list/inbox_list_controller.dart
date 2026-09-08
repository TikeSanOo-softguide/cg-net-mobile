import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model/user_model.dart';

class InboxListController
    extends StateNotifier<AsyncValue<List<InboxMessageModel>>> {
  InboxListController() : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = AsyncValue.data([
      InboxMessageModel(
        id: '1',
        title: 'Scheduled maintenance',
        body: 'Network maintenance tonight 01:00–03:00.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      InboxMessageModel(
        id: '2',
        title: 'Invoice ready',
        body: 'Your March invoice is available in the app.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
      InboxMessageModel(
        id: '3',
        title: 'Welcome to CG Net',
        body: 'Thanks for joining. Explore packages and support anytime.',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: true,
      ),
    ]);
  }
}

final inboxListControllerProvider = StateNotifierProvider<InboxListController,
    AsyncValue<List<InboxMessageModel>>>((ref) {
  return InboxListController();
});
