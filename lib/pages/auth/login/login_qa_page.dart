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
import '../../../data/settings/general_setting_repository.dart';
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

  static TextStyle get _bodyStyle =>
      AppTheme.bodySecondary(color: AppColors.textMuted);

  static TextStyle get _titleStyle => AppTheme.sectionTitle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(appLocaleProvider);
    final faqAsync = ref.watch(faqProvider);
    final supportContactsAsync = ref.watch(supportContactProvider);
    final _ = context.locale;

    final faqItems = faqAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return <_QaItemData>[];
        }

        return items
            .map(
              (item) => _QaItemData(
                question: item.titleFor(localeCode),
                answer: item.descriptionFor(localeCode),
              ),
            )
            .toList();
      },
      loading: () => <_QaItemData>[],
      error: (_, __) => <_QaItemData>[],
    );

    final hotlineNumbers = supportContactsAsync.when(
      data: (items) {
        final phonesByCountry = <CountryDial, List<String>>{};

        for (final contact in items) {
          final phone = contact.phone.replaceAll(
            RegExp(r'[^\d+]'),
            '',
          );

          for (final country in CountryDial.values) {
            if (phone.startsWith(country.dialCode)) {
              final localNumber = phone.substring(country.dialCode.length);

              if (localNumber.isNotEmpty) {
                phonesByCountry
                    .putIfAbsent(country, () => <String>[])
                    .add(localNumber);
              }

              break;
            }
          }
        }

        return [
          for (final country in CountryDial.values)
            for (final phone in phonesByCountry[country] ?? <String>[])
              (country, phone),
        ];
      },
      loading: () => const <(CountryDial, String)>[],
      error: (_, __) => const <(CountryDial, String)>[],
    );

    final qaWidgets = faqItems.isNotEmpty
        ? faqItems
            .map(
              (item) => _QaItem(
                question: item.question,
                answer: item.answer,
                titleStyle: _titleStyle,
                bodyStyle: _bodyStyle,
              ),
            )
            .toList()
        : [
            for (var i = 0; i < _items.length; i += 2)
              _QaItem(
                question: _items[i].tr(),
                answer: _items[i + 1].tr(),
                titleStyle: _titleStyle,
                bodyStyle: _bodyStyle,
              ),
          ];

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
          ...qaWidgets,
          const SizedBox(height: AppStyle.spaceSm),
          _HotlineSection(
            hotlines: hotlineNumbers.isNotEmpty
                ? hotlineNumbers
                : supportContactsAsync.hasValue &&
                        supportContactsAsync.value!.isNotEmpty
                    ? const []
                    : _hotlines
                        .map(
                          (entry) => (entry.$1, entry.$2.tr()),
                        )
                        .toList(),
            titleStyle: _titleStyle,
            bodyStyle: _bodyStyle,
          ),
        ],
      ),
    );
  }
}

class _QaItemData {
  const _QaItemData({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;
}

class _QaItem extends StatefulWidget {
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
  State<_QaItem> createState() => _QaItemState();
}

class _QaItemState extends State<_QaItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(
        bottom: AppStyle.spaceSm,
      ),
      decoration: BoxDecoration(
        color: _isExpanded
            ? AppColors.primarySoft.withValues(alpha: 0.7)
            : AppColors.primarySoft,
        borderRadius: AppStyle.borderRadiusSm,
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppStyle.borderRadiusSm,
        child: InkWell(
          borderRadius: AppStyle.borderRadiusSm,
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppStyle.spaceMd,
              vertical: AppStyle.spaceSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.help_outline,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppStyle.spaceSm),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: widget.titleStyle,
                      ),
                    ),
                    const SizedBox(width: AppStyle.spaceSm),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: AppStyle.iconSizeSm,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: AppStyle.spaceSm),
                  const Divider(height: 1, color: AppColors.borderLight),
                  const SizedBox(height: AppStyle.spaceSm),
                  Padding(
                    padding: const EdgeInsets.only(left: AppStyle.spaceXxl),
                    child: Text(
                      widget.answer,
                      style: widget.bodyStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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

  Future<void> _openContactDialog(
    BuildContext context, {
    required CountryDial country,
    required String localNumber,
  }) async {
    final displayNumber = '${country.dialCode} $localNumber';
    final digits = displayNumber.replaceAll(
      RegExp(r'[^\d+]'),
      '',
    );
    final telDigits = digits.replaceAll('+', '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: AppStyle.borderRadiusLg,
          ),
          title: Text('login.contact_via'.tr()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayNumber,
                  style: AppTheme.body(
                    color: AppColors.textPrimary,
                    weight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceLg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _ContactOption(
                        icon: LucideIcons.phone,
                        label: 'login.contact_phone'.tr(),
                        onTap: () async {
                          Navigator.pop(dialogContext);

                          await _launchUri(
                            context,
                            Uri(
                              scheme: 'tel',
                              path: digits,
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _ContactOption(
                        icon: Icons.chat_bubble_rounded,
                        label: 'login.contact_viber'.tr(),
                        onTap: () async {
                          Navigator.pop(dialogContext);

                          await _launchUri(
                            context,
                            Uri.parse(
                              'viber://chat?number=$telDigits',
                            ),
                            fallbackUrl: 'https://www.viber.com/',
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _ContactOption(
                        icon: Icons.send_outlined,
                        label: 'login.contact_telegram'.tr(),
                        onTap: () async {
                          Navigator.pop(dialogContext);

                          await _launchUri(
                            context,
                            Uri.parse(
                              'https://t.me/+$telDigits',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _tryLaunch(Uri uri) async {
    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _launchUri(
    BuildContext context,
    Uri uri, {
    String? fallbackUrl,
  }) async {
    var launched = await _tryLaunch(uri);

    if (!launched && fallbackUrl != null) {
      launched = await _tryLaunch(
        Uri.parse(fallbackUrl),
      );
    }

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'login.contact_error'.tr(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: AppStyle.borderRadiusSm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppStyle.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.headset_mic_outlined,
                  size: 14,
                  color: AppColors.primary.withValues(
                    alpha: 0.85,
                  ),
                ),
                const SizedBox(width: AppStyle.spaceXs),
                Text(
                  'login.hotline_title'.tr(),
                  style: AppTheme.bodySecondary(
                    color: AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: AppStyle.spaceSm),
            for (final entry in hotlines)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppStyle.spaceXs,
                ),
                child: InkWell(
                  onTap: () => _openContactDialog(
                    context,
                    country: entry.$1,
                    localNumber: entry.$2,
                  ),
                  borderRadius: AppStyle.borderRadiusInput,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppStyle.spaceSm,
                      vertical: AppStyle.spaceXs,
                    ),
                    child: Row(
                      children: [
                        Text(
                          entry.$1.flag,
                          style: AppTheme.english(
                            fontSize: AppStyle.fontBodyLg,
                            height: AppTheme.lineHeightMyanmarSafe,
                          ),
                        ),
                        const SizedBox(width: AppStyle.spaceSm),
                        Text(
                          entry.$1.dialCode,
                          style: bodyStyle.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: AppStyle.spaceSm),
                        Expanded(
                          child: Text(
                            entry.$2,
                            style: bodyStyle.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
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
    return InkWell(
      borderRadius: AppStyle.borderRadiusSm,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppStyle.spaceXs,
          vertical: AppStyle.spaceXs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: AppStyle.iconBox,
              height: AppStyle.iconBox,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppStyle.borderRadiusSm,
              ),
              child: Icon(
                icon,
                size: AppStyle.iconSize,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppStyle.spaceXs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.caption(
                color: AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
