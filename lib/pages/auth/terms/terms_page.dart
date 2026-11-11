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

  static const _iconAsset = 'assets/images/settings/terms.png';

  static const double _iconBoxSize = 45;
  static const double _iconSize = 26;
  static const double _iconRadius = 10;
  static const double _cardRadius = 8;
  static const double _contentPadding = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(appLocaleProvider);
    final termsAsync = ref.watch(termAndConditionProvider);

    final titleText = termsAsync.when(
      data: (items) {
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
              width: _iconBoxSize,
              height: _iconBoxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(_iconRadius),
              ),
              child: Image.asset(
                _iconAsset,
                width: _iconSize,
                height: _iconSize,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(height: AppStyle.spaceLg),
          Text(
            titleText,
            textAlign: TextAlign.center,
            style: AppTheme.english(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppStyle.spaceXl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(_contentPadding),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(_cardRadius),
            ),
            child: Text(
              bodyText,
              textAlign: TextAlign.start,
              style: AppTheme.english(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.5,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
