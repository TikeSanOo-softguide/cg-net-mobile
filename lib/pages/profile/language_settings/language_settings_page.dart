import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import 'language_settings_controller.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep selection in sync with the live app locale.
    final liveCode = context.locale.languageCode;
    final code = ref.watch(languageSettingsControllerProvider);
    final selected = code == liveCode ? code : liveCode;
    final controller = ref.read(languageSettingsControllerProvider.notifier);

    return AppCurvedScaffold(
      title: Text('profile.language_title'.tr()),
      showBack: true,
      body: ListView(
        children: [
          _item(context, 'en', 'language.english'.tr(), selected, controller),
          _item(context, 'my', 'language.myanmar'.tr(), selected, controller),
          _item(context, 'zh', 'language.chinese'.tr(), selected, controller),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String value,
    String label,
    String selected,
    LanguageSettingsController controller,
  ) {
    return ListTile(
      title: Text(label),
      trailing: selected == value
          ? const Icon(LucideIcons.circle_check, color: AppColors.secondary)
          : null,
      onTap: () => controller.change(context, value),
    );
  }
}
