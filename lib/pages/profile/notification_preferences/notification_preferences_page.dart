import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_preferences_controller.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesControllerProvider);
    final controller =
        ref.read(notificationPreferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('profile.notifications_title'.tr())),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text('profile.push_notifications'.tr()),
            value: prefs.push,
            onChanged: controller.setPush,
          ),
          SwitchListTile(
            title: Text('profile.email_notifications'.tr()),
            value: prefs.email,
            onChanged: controller.setEmail,
          ),
          SwitchListTile(
            title: Text('profile.sms_notifications'.tr()),
            value: prefs.sms,
            onChanged: controller.setSms,
          ),
        ],
      ),
    );
  }
}
