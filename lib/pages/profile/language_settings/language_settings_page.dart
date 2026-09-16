import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'language_settings_controller.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  static const _options = [
    ('en', 'language.english', 'assets/images/flags/en.png'),
    ('my', 'language.myanmar', 'assets/images/flags/my.png'),
    ('zh', 'language.chinese', 'assets/images/flags/zh.png'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveCode = context.locale.languageCode;
    final code = ref.watch(languageSettingsControllerProvider);
    final selected = code == liveCode ? code : liveCode;
    final controller = ref.read(languageSettingsControllerProvider.notifier);

    return AppCurvedScaffold(
      title: Text('profile.language_title'.tr()),
      showBack: true,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          for (final option in _options) ...[
            AppCard(
              elevated: false,
              bordered: true,
              color: selected == option.$1
                  ? AppColors.primarySoft
                  : AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => controller.change(context, option.$1),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 28,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      option.$3,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: AppColors.primaryLight,
                        child: Icon(
                          LucideIcons.globe,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option.$2.tr(),
                      style: AppTheme.english(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    selected == option.$1
                        ? LucideIcons.circle_check
                        : LucideIcons.circle,
                    size: 20,
                    color: selected == option.$1
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
