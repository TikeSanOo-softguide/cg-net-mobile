import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _iconAsset = 'assets/images/auth/terms.png';

  @override
  Widget build(BuildContext context) {
    return AuthBackgroundScaffold(
      showBack: true,
      compactTop: true,
      topBarTitle: 'terms.title'.tr(),
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                _iconAsset,
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          const SizedBox(height: AppStyle.spaceLg),
          Text(
            'terms.title'.tr(),
            textAlign: TextAlign.center,
            style: AppTheme.english(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppStyle.spaceLg),
          Text(
            'terms.body'.tr(),
            style: AppTheme.english(
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
