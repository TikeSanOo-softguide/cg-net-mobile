import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_logo/app_logo.dart';
import '../../../core/utils/version_check/version_check.dart';
import 'about_app_controller.dart';

class AboutAppPage extends ConsumerWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(aboutAppControllerProvider);
    final versionAsync = ref.watch(packageInfoProvider);

    return AppCurvedScaffold(
      title: Text('profile.about_title'.tr()),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: AppLogo(
              size: 88,
              padding: 12,
              borderRadius: 18,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'app_name'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          versionAsync.when(
            data: (info) => Text(
              '${'profile.version'.tr()} ${info.version} (${info.buildNumber})',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(
              'profile.version'.tr(),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'profile.icon_credits'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            'https://www.flaticon.com/free-icons/receipt',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
