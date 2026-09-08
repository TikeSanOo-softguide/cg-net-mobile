import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/version_check/version_check.dart';
import 'about_app_controller.dart';

class AboutAppPage extends ConsumerWidget {
  const AboutAppPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(aboutAppControllerProvider);
    final versionAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      appBar: AppBar(title: Text('profile.about_title'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                'assets/images/cg_net_logo.png',
                width: 72,
                height: 72,
                fit: BoxFit.contain,
              ),
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
        ],
      ),
    );
  }
}
