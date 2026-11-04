import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/inbox/inbox_repository.dart';
import '../../../models/user_model/user_model.dart';
import 'inbox_unread_count.dart';

final inboxListOfflineProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class InboxListController
    extends StateNotifier<AsyncValue<List<InboxMessageModel>>> {
  InboxListController(
    this._repository,
    this._setOffline,
    this._setUnread,
    this._currentBadge,
  ) : super(const AsyncValue.loading()) {
    final cached = _repository.readCache();
    if (cached != null) {
      state = AsyncValue.data(cached);
      load(silent: true);
    } else {
      load();
    }
  }

  final InboxRepository _repository;
  final void Function(bool offline) _setOffline;
  final void Function(int count) _setUnread;
  final int Function() _currentBadge;
  CancelToken? _cancel;

  /// [silent] keeps the current list visible, e.g. for pull-to-refresh.
  /// [rethrowOffline] lets the network-recovery queue try again later.
  Future<void> load({bool silent = false, bool rethrowOffline = false}) async {
    _cancel?.cancel();
    final cancelToken = CancelToken();
    _cancel = cancelToken;
    if (!silent || !state.hasValue) state = const AsyncValue.loading();
    try {
      final result = await _repository.fetch(cancelToken: cancelToken);
      if (!mounted || cancelToken.isCancelled) return;
      final items = result.items;
      final merged = _keepLocalReads(items);
      await _repository.saveCache(merged);
      if (!mounted || cancelToken.isCancelled) return;
      _setOffline(false);
      state = AsyncValue.data(merged);
      _setUnread(_badgeCount(result.unreadCount, items, merged));
      _syncPendingReads(items, merged);
    } on ApiException catch (error, stackTrace) {
      if (!mounted || error.failure == ApiFailure.cancelled) return;
      if (error.failure == ApiFailure.offline) {
        final cached = state.valueOrNull ?? _repository.readCache();
        if (cached != null) {
          _setOffline(true);
          state = AsyncValue.data(cached);
          if (rethrowOffline) throw error;
          return;
        }
      } else if (state.hasValue) {
        return;
      }
      _setOffline(false);
      state = AsyncValue.error(error, stackTrace);
      if (rethrowOffline && error.failure == ApiFailure.offline) throw error;
    }
  }

  /// Opening a notification marks it read and clears the unread marker.
  Future<void> markRead(String id) async {
    if (int.tryParse(id) == null) return;
    final wasUnread = state.valueOrNull?.any(
          (item) => item.id == id && !item.isRead,
        ) ??
        false;
    _setRead(id, true);
    if (wasUnread) _setUnread(_currentBadge() - 1);
    try {
      await _repository.markAsRead(id);
      if (!mounted) return;
      _setRead(id, true);
    } on ApiException catch (error) {
      if (!mounted || error.failure == ApiFailure.offline) return;
      _setRead(id, false);
      if (wasUnread) _setUnread(_currentBadge() + 1);
    }
  }

  int _badgeCount(
    int serverUnread,
    List<InboxMessageModel> serverItems,
    List<InboxMessageModel> merged,
  ) {
    final readLocally = {
      for (final item in merged)
        if (item.isRead) item.id,
    };
    final pending = serverItems
        .where((item) => !item.isRead && readLocally.contains(item.id))
        .length;
    final next = serverUnread - pending;
    return next < 0 ? 0 : next;
  }

  List<InboxMessageModel> _keepLocalReads(List<InboxMessageModel> items) {
    final locallyRead = {
      for (final item in state.valueOrNull ?? const <InboxMessageModel>[])
        if (item.isRead) item.id,
    };
    return [
      for (final item in items)
        locallyRead.contains(item.id) && !item.isRead
            ? item.copyWith(isRead: true)
            : item,
    ];
  }

  void _syncPendingReads(
    List<InboxMessageModel> serverItems,
    List<InboxMessageModel> merged,
  ) {
    final serverUnread = {
      for (final item in serverItems)
        if (!item.isRead) item.id,
    };
    for (final item in merged) {
      if (!item.isRead || !serverUnread.contains(item.id)) continue;
      unawaited(_repository.markAsRead(item.id).catchError((Object _) {}));
    }
  }

  void _setRead(String id, bool isRead) {
    final current = state.valueOrNull;
    if (current == null || !mounted) return;
    final index = current.indexWhere((item) => item.id == id);
    if (index < 0 || current[index].isRead == isRead) return;
    final next = [...current];
    next[index] = current[index].copyWith(isRead: isRead);
    state = AsyncValue.data(next);
    _repository.saveCache(next);
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }
}

final inboxListControllerProvider = StateNotifierProvider.autoDispose<
    InboxListController, AsyncValue<List<InboxMessageModel>>>((ref) {
  return InboxListController(
    ref.watch(inboxRepositoryProvider),
    (offline) => ref.read(inboxListOfflineProvider.notifier).state = offline,
    (count) => ref.read(inboxUnreadCountProvider.notifier).setCount(count),
    () => ref.read(inboxUnreadCountProvider),
  );
});
