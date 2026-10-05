import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/inbox/inbox_repository.dart';
import '../../../models/user_model/user_model.dart';

class InboxListController
    extends StateNotifier<AsyncValue<List<InboxMessageModel>>> {
  InboxListController(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final InboxRepository _repository;
  CancelToken? _cancel;

  /// [silent] keeps the current list visible, e.g. for pull-to-refresh.
  Future<void> load({bool silent = false}) async {
    _cancel?.cancel();
    final cancelToken = CancelToken();
    _cancel = cancelToken;
    if (!silent || !state.hasValue) state = const AsyncValue.loading();
    try {
      final items = await _repository.fetch(cancelToken: cancelToken);
      if (!mounted || cancelToken.isCancelled) return;
      state = AsyncValue.data(items);
    } on ApiException catch (error, stackTrace) {
      if (!mounted || error.failure == ApiFailure.cancelled) return;
      state = AsyncValue.error(error, stackTrace);
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }
}

final inboxListControllerProvider = StateNotifierProvider.autoDispose<
    InboxListController, AsyncValue<List<InboxMessageModel>>>((ref) {
  return InboxListController(ref.watch(inboxRepositoryProvider));
});
