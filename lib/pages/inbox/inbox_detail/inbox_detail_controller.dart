import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/promotion/promotion_repository.dart';
import '../../../models/user_model/user_model.dart';
import '../inbox_list/inbox_list_controller.dart';

final inboxDetailControllerProvider =
    Provider.family<AsyncValue<InboxMessageModel>, String>((ref, id) {
  final catalogId = promotionCatalogId(id);
  if (catalogId != null) {
    return ref.watch(promotionDetailProvider(catalogId)).whenData(
          (promotion) => promotion.toInboxMessage(),
        );
  }

  final listAsync = ref.watch(inboxListControllerProvider);
  return listAsync.whenData((list) {
    return list.firstWhere(
      (m) => m.id == id,
      orElse: () => InboxMessageModel(
        id: id,
        titleKey: 'inbox.detail_fallback_title',
        bodyKey: 'inbox.detail_fallback_body',
        createdAt: DateTime.now(),
        category: InboxCategory.system,
      ),
    );
  });
});
