import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/settings/general_setting_repository.dart';
import '../../../core/locale/app_locale_provider.dart';

class TermsPage extends ConsumerWidget {
  const TermsPage({super.key});

  static const _iconAsset = 'assets/images/auth/terms.png';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(appLocaleProvider);
    final termsAsync = ref.watch(termAndConditionProvider);

    final titleText = termsAsync.when(
      data: (items) {
        if (items.isEmpty) return 'terms.title'.tr();
        final text = items
            .map((item) => item.titleFor(localeCode))
            .where((value) => value.trim().isNotEmpty)
            .join('\n\n');
        return text.isEmpty ? 'terms.title'.tr() : text;
      },
      loading: () => 'terms.title'.tr(),
      error: (_, __) => 'terms.title'.tr(),
    );

    final bodyText = termsAsync.when(
      data: (items) {
        if (items.isEmpty) return 'terms.body'.tr();
        final text = items
            .map((item) => item.descriptionFor(localeCode))
            .where((value) => value.trim().isNotEmpty)
            .join('\n\n');
        return text.isEmpty ? 'terms.body'.tr() : text;
      },
      loading: () => 'terms.body'.tr(),
      error: (_, __) => 'terms.body'.tr(),
    );

    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      topBarTitle: 'terms.title'.tr(),
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: AppStyle.iconBox,
              height: AppStyle.iconBox,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppStyle.borderRadiusLg,
              ),
              child: Center(
                child: Image.asset(
                  _iconAsset,
                  width: AppStyle.iconSize,
                  height: AppStyle.iconSize,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppStyle.spaceXl),
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: AppTheme.pageTitle(color: AppColors.primary),
          ),
          const SizedBox(height: AppStyle.spaceXxl),
          Container(
            padding: AppStyle.cardPadding,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.25),
              borderRadius: AppStyle.borderRadiusLg,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bodyText,
                  textAlign: TextAlign.start,
                  style: AppTheme.body(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
