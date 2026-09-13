import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

class LoginQaPage extends ConsumerWidget {
  const LoginQaPage({super.key});

  static const _items = [
    'login.qa_q1',
    'login.qa_a1',
    'login.qa_q2',
    'login.qa_a2',
    'login.qa_q3',
    'login.qa_a3',
    'login.qa_q4',
    'login.qa_a4',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(appLocaleProvider);
    final _ = context.locale;

    return AuthBackgroundScaffold(
      key: ValueKey('login-qa-$localeCode'),
      showBack: true,
      topBarTitle: 'login.qa_title'.tr(),
      card: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'login.qa_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: AppTheme.captionSm(color: AppColors.textMuted).copyWith(
              fontSize: 11,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppStyle.spaceMd),
          for (var i = 0; i < _items.length; i += 2)
            _QaItem(
              question: _items[i].tr(),
              answer: _items[i + 1].tr(),
            ),
        ],
      ),
    );
  }
}

class _QaItem extends StatelessWidget {
  const _QaItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyle.spaceSm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyle.spaceMd,
        vertical: AppStyle.spaceSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: AppStyle.borderRadiusSm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  question,
                  style: AppTheme.english(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              answer,
              style: AppTheme.english(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
