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
        titleKey: 'inbox.msg1_title',
        bodyKey: 'inbox.msg1_body',
        detailKey: 'inbox.msg1_detail',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        category: InboxCategory.system,
      ),
      InboxMessageModel(
        id: '2',
        titleKey: 'inbox.msg2_title',
        bodyKey: 'inbox.msg2_body',
        detailKey: 'inbox.msg2_detail',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        category: InboxCategory.promotion,
      ),
      InboxMessageModel(
        id: '3',
        titleKey: 'inbox.msg3_title',
        bodyKey: 'inbox.msg3_body',
        detailKey: 'inbox.msg3_detail',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        category: InboxCategory.announcement,
        isRead: true,
      ),
      InboxMessageModel(
        id: '4',
        titleKey: 'inbox.msg4_title',
        bodyKey: 'inbox.msg4_body',
        detailKey: 'inbox.msg4_detail',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        category: InboxCategory.system,
        isRead: true,
      ),
      InboxMessageModel(
        id: '5',
        titleKey: 'inbox.msg5_title',
        bodyKey: 'inbox.msg5_body',
        detailKey: 'inbox.msg5_detail',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        category: InboxCategory.announcement,
        isRead: true,
      ),
      InboxMessageModel(
        id: '6',
        titleKey: 'inbox.msg6_title',
        bodyKey: 'inbox.msg6_body',
        detailKey: 'inbox.msg6_detail',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        category: InboxCategory.promotion,
        isRead: true,
      ),
    ]);
  }
}

final inboxListControllerProvider = StateNotifierProvider<InboxListController,
    AsyncValue<List<InboxMessageModel>>>((ref) {
  return InboxListController();
});
