import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/inbox_category_icon/inbox_category_icon.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/notification_preferences_model/notification_preferences_model.dart';
import '../../../models/user_model/user_model.dart';
import 'notification_preferences_controller.dart';

class NotificationPreferencesPage extends ConsumerWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesAsync =
        ref.watch(notificationPreferencesControllerProvider);
    final controller =
        ref.read(notificationPreferencesControllerProvider.notifier);

    return AppCurvedScaffold(
      title: Text('profile.notifications_title'.tr()),
      showBack: true,
      body: preferencesAsync.when(
        data: (preferences) => _preferencesList(
          context,
          controller,
          preferences,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('profile.notifications_load_failed'.tr()),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.reload,
                child: Text('common.retry'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preferencesList(
    BuildContext context,
    NotificationPreferencesController controller,
    NotificationPreferencesModel preferences,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
      children: [
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          borderRadius: AppStyle.borderRadiusLg,
          child: Column(
            children: [
              _NotificationPreferenceTile(
                icon: const InboxCategoryIcon(
                  category: InboxCategory.announcement,
                  size: 32,
                  iconSize: 18,
                ),
                title: 'profile.announcements_notifications'.tr(),
                value: preferences.announcements,
                onChanged: (value) => _save(
                  context,
                  () => controller.setAnnouncements(value),
                ),
              ),
              const _PreferenceDivider(),
              _NotificationPreferenceTile(
                icon: const InboxCategoryIcon(
                  category: InboxCategory.system,
                  size: 32,
                  iconSize: 18,
                ),
                title: 'profile.system_notifications'.tr(),
                value: preferences.system,
                onChanged: (value) => _save(
                  context,
                  () => controller.setSystem(value),
                ),
              ),
              const _PreferenceDivider(),
              _NotificationPreferenceTile(
                icon: const InboxCategoryIcon(
                  category: InboxCategory.promotion,
                  size: 32,
                  iconSize: 18,
                ),
                title: 'profile.promotion_notifications'.tr(),
                value: preferences.promotion,
                onChanged: (value) => _save(
                  context,
                  () => controller.setPromotion(value),
                ),
              ),
              const _PreferenceDivider(),
              _NotificationPreferenceTile(
                icon: const QuickActionIconChip(
                  asset: 'assets/images/profile/notification.png',
                  background: AppColors.primaryLight,
                  size: 32,
                  iconSize: 18,
                ),
                title: 'profile.general_notifications'.tr(),
                value: preferences.general,
                onChanged: (value) => _save(
                  context,
                  () => controller.setGeneral(value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save(
    BuildContext context,
    Future<void> Function() update,
  ) async {
    try {
      await update();
    } on ApiException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile.notifications_update_failed'.tr())),
      );
    }
  }
}

class _NotificationPreferenceTile extends StatelessWidget {
  const _NotificationPreferenceTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final Widget icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: AppTheme.body(
                weight: FontWeight.w500,
              ),
            ),
          ),
          Transform.scale(
            scale: 0.72,
            alignment: Alignment.centerRight,
            child: Switch(
              value: value,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceDivider extends StatelessWidget {
  const _PreferenceDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.borderLight,
      indent: 44,
    );
  }
}
