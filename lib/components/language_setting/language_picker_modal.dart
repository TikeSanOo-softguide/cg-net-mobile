import 'package:cg_net_mobile/pages/profile/language_settings/language_settings_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

const _languageOptions = [
  ('en', 'language.english', 'assets/images/flags/en.png'),
  ('my', 'language.myanmar', 'assets/images/flags/my.png'),
  ('zh', 'language.chinese', 'assets/images/flags/zh.png'),
];

Future<void> showLanguagePickerModal({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();

  final selected = ref.read(languageSettingsControllerProvider);
  final controller = ref.read(languageSettingsControllerProvider.notifier);

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppStyle.radiusCurve),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'profile.language_title'.tr(),
                style: AppTheme.english(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              for (final option in _languageOptions)
                _LanguageOption(
                  flagAsset: option.$3,
                  label: option.$2.tr(),
                  selected: selected == option.$1,
                  onTap: () async {
                    try {
                      await controller.change(context, option.$1);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                    } on ApiException catch (error) {
                      if (!sheetContext.mounted) return;
                      ScaffoldMessenger.of(sheetContext)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(content: Text(apiErrorOrFallback(error))),
                        );
                    }
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.flagAsset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String flagAsset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 24,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderLight),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          flagAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: AppColors.primaryLight,
            child: Icon(
              LucideIcons.globe,
              size: 12,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
      title: Text(
        label,
        style: AppTheme.english(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: selected
          ? const Icon(
              LucideIcons.circle_check,
              color: AppColors.primary,
              size: 20,
            )
          : null,
    );
  }
}
