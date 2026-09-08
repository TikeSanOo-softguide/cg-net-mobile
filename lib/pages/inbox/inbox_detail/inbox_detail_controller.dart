import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model/user_model.dart';
import '../inbox_list/inbox_list_controller.dart';

final inboxDetailControllerProvider =
    Provider.family<AsyncValue<InboxMessageModel>, String>((ref, id) {
  final listAsync = ref.watch(inboxListControllerProvider);
  return listAsync.whenData((list) {
    return list.firstWhere(
      (m) => m.id == id,
      orElse: () => InboxMessageModel(
        id: id,
        title: 'Message',
        body: 'Message details unavailable.',
        createdAt: DateTime.now(),
      ),
    );
  });
});
