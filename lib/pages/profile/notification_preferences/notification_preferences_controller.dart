import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/notification_preferences/notification_preferences_repository.dart';
import '../../../models/notification_preferences_model/notification_preferences_model.dart';

class NotificationPreferencesController
    extends AsyncNotifier<NotificationPreferencesModel> {
  @override
  Future<NotificationPreferencesModel> build() {
    return ref.watch(notificationPreferencesRepositoryProvider).fetch();
  }

  Future<void> setAnnouncements(bool value) {
    return _save(state.requireValue.copyWith(announcements: value));
  }

  Future<void> setSystem(bool value) {
    return _save(state.requireValue.copyWith(system: value));
  }

  Future<void> setPromotion(bool value) {
    return _save(state.requireValue.copyWith(promotion: value));
  }

  Future<void> setGeneral(bool value) {
    return _save(state.requireValue.copyWith(general: value));
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(notificationPreferencesRepositoryProvider).fetch(),
    );
  }

  Future<void> _save(NotificationPreferencesModel updated) async {
    final previous = state.requireValue;
    state = AsyncData(updated);
    try {
      await ref.read(notificationPreferencesRepositoryProvider).update(updated);
    } on ApiException {
      state = AsyncData(previous);
      rethrow;
    }
  }
}

final notificationPreferencesControllerProvider = AsyncNotifierProvider<
    NotificationPreferencesController, NotificationPreferencesModel>(
  NotificationPreferencesController.new,
);
