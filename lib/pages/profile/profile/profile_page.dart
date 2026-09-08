import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import 'profile_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('profile.title'.tr())),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              profile.fullName.isNotEmpty
                  ? profile.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 28,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.fullName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            profile.phone,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _tile(
            context,
            Icons.edit_outlined,
            'profile.edit'.tr(),
            RouteNames.editProfile,
          ),
          _tile(
            context,
            Icons.language,
            'profile.language'.tr(),
            RouteNames.languageSettings,
          ),
          _tile(
            context,
            Icons.lock_outline,
            'profile.change_password'.tr(),
            RouteNames.changePassword,
          ),
          _tile(
            context,
            Icons.devices,
            'profile.devices'.tr(),
            RouteNames.deviceSession,
          ),
          _tile(
            context,
            Icons.notifications_outlined,
            'profile.notifications'.tr(),
            RouteNames.notificationPreferences,
          ),
          _tile(
            context,
            Icons.info_outline,
            'profile.about'.tr(),
            RouteNames.aboutApp,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              'common.logout'.tr(),
              style: const TextStyle(color: AppColors.error),
            ),
            onTap: () async {
              await ref.read(profileControllerProvider.notifier).logout();
              if (context.mounted) {
                context.goNamed(RouteNames.login);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String routeName,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.pushNamed(routeName),
    );
  }
}
