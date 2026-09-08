import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import 'language_settings_controller.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = ref.watch(languageSettingsControllerProvider);
    final controller = ref.read(languageSettingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('profile.language_title'.tr())),
      body: ListView(
        children: [
          _item(context, 'en', 'language.english'.tr(), code, controller),
          _item(context, 'my', 'language.myanmar'.tr(), code, controller),
          _item(context, 'zh', 'language.chinese'.tr(), code, controller),
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
          ? const Icon(Icons.check_circle, color: AppColors.secondary)
          : null,
      onTap: () => controller.change(context, value),
    );
  }
}
