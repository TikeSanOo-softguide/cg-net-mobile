import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../components/common_auth_card/common_auth_card.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'login_controller.dart';

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

  static const _hotlines = [
    (CountryDial.myanmar, 'login.hotline_mm_local'),
    (CountryDial.thailand, 'login.hotline_th_local'),
    (CountryDial.china, 'login.hotline_cn_local'),
  ];

  static TextStyle get _bodyStyle => AppTheme.english(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
        height: 1.4,
        letterSpacing: 0.2,
      );

  static TextStyle get _titleStyle => AppTheme.english(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.4,
        letterSpacing: 0.2,
      );

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
            style: _bodyStyle,
          ),
          const SizedBox(height: AppStyle.spaceMd),
          for (var i = 0; i < _items.length; i += 2)
            _QaItem(
              question: _items[i].tr(),
              answer: _items[i + 1].tr(),
              titleStyle: _titleStyle,
              bodyStyle: _bodyStyle,
            ),
          const SizedBox(height: AppStyle.spaceSm),
          _HotlineSection(
            hotlines: _hotlines,
            titleStyle: _titleStyle,
            bodyStyle: _bodyStyle,
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
    required this.titleStyle,
    required this.bodyStyle,
  });

  final String question;
  final String answer;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;

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
              Expanded(child: Text(question, style: titleStyle)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(answer, style: bodyStyle),
          ),
        ],
      ),
    );
  }
}

class _HotlineSection extends StatelessWidget {
  const _HotlineSection({
    required this.hotlines,
    required this.titleStyle,
    required this.bodyStyle,
  });

  final List<(CountryDial, String)> hotlines;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;

  Future<void> _openContactSheet(
    BuildContext context, {
    required CountryDial country,
    required String localNumber,
  }) async {
    final displayNumber = '${country.dialCode} $localNumber';
    final digits = displayNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final telDigits = digits.replaceAll('+', '');

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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  'login.contact_via'.tr(),
                  style: AppTheme.english(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayNumber,
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 12),
                _ContactOption(
                  icon: LucideIcons.phone,
                  label: 'login.contact_phone'.tr(),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _launchUri(Uri(scheme: 'tel', path: digits));
                  },
                ),
                _ContactOption(
                  icon: Icons.chat_bubble_outline,
                  label: 'login.contact_viber'.tr(),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _launchUri(
                      Uri.parse('viber://chat?number=$telDigits'),
                    );
                  },
                ),
                _ContactOption(
                  icon: Icons.send_outlined,
                  label: 'login.contact_telegram'.tr(),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _launchUri(Uri.parse('https://t.me/+$telDigits'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchUri(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // App may not be installed — ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline,
                  size: 13,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  'login.hotline_title'.tr(),
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    height: 1.3,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            for (final entry in hotlines)
              InkWell(
                onTap: () => _openContactSheet(
                  context,
                  country: entry.$1,
                  localNumber: entry.$2.tr(),
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        entry.$1.flag,
                        style: const TextStyle(fontSize: 14, height: AppTheme.lineHeightMyanmarSafe),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.$1.dialCode,
                        style: bodyStyle.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.$2.tr(),
                          style: bodyStyle.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  const _ContactOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: AppStyle.borderRadiusSm,
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
      title: Text(
        label,
        style: AppTheme.english(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
