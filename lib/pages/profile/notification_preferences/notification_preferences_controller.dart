import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationPrefs {
  const NotificationPrefs({
    this.push = true,
    this.email = true,
    this.sms = false,
  });

  final bool push;
  final bool email;
  final bool sms;

  NotificationPrefs copyWith({bool? push, bool? email, bool? sms}) {
    return NotificationPrefs(
      push: push ?? this.push,
      email: email ?? this.email,
      sms: sms ?? this.sms,
    );
  }
}

class NotificationPreferencesController
    extends StateNotifier<NotificationPrefs> {
  NotificationPreferencesController() : super(const NotificationPrefs());

  void setPush(bool value) => state = state.copyWith(push: value);
  void setEmail(bool value) => state = state.copyWith(email: value);
  void setSms(bool value) => state = state.copyWith(sms: value);
}

final notificationPreferencesControllerProvider = StateNotifierProvider<
    NotificationPreferencesController, NotificationPrefs>((ref) {
  return NotificationPreferencesController();
});
