import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/local_prefs/local_prefs.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';
import '../../../data/inbox/inbox_repository.dart';

class InboxUnreadCountController extends Notifier<int> {
  @override
  int build() {
    return ref
            .watch(sharedPreferencesProvider)
            .getInt(LocalPrefs.inboxUnreadCountKey) ??
        0;
  }

  void setCount(int count) {
    final next = count < 0 ? 0 : count;
    state = next;
    ref
        .read(sharedPreferencesProvider)
        .setInt(LocalPrefs.inboxUnreadCountKey, next);
  }

  void clear() => setCount(0);

  /// Asks the server for the current unread total.
  Future<void> refresh() async {
    if (!await ref.read(secureStorageProvider).hasToken()) return;
    try {
      final count = await ref.read(inboxRepositoryProvider).fetchUnreadCount();
      setCount(count);
    } on ApiException {
      // Keep the last badge when the reconcile request fails.
    }
  }
}

final inboxUnreadCountProvider =
    NotifierProvider<InboxUnreadCountController, int>(
  InboxUnreadCountController.new,
);
