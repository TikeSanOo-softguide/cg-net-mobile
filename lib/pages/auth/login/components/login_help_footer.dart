import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../login_controller.dart';

/// Help block under login CTA — soft card, Q&A link, aligned hotlines.
class LoginHelpFooter extends StatefulWidget {
  const LoginHelpFooter({super.key});

  @override
  State<LoginHelpFooter> createState() => _LoginHelpFooterState();
}

class _LoginHelpFooterState extends State<LoginHelpFooter> {
  static const _hotlines = [
    (CountryDial.myanmar, 'login.hotline_mm'),
    (CountryDial.thailand, 'login.hotline_th'),
    (CountryDial.china, 'login.hotline_cn'),
  ];

  late final TapGestureRecognizer _qaTap;

  @override
  void initState() {
    super.initState();
    _qaTap = TapGestureRecognizer()
      ..onTap = () {
        context.pushNamed(RouteNames.loginQa);
      };
  }

  @override
  void dispose() {
    _qaTap.dispose();
    super.dispose();
  }

  Future<void> _openContactSheet(
    BuildContext context, {
    required String displayNumber,
  }) async {
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
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayNumber,
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
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
    final _ = context.locale;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text.rich(
            TextSpan(
              style: AppTheme.english(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
                height: 1.3,
              ),
              children: [
                const WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.help_outline,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                TextSpan(text: 'login.help_prefix'.tr()),
                TextSpan(
                  text: 'login.help_qa'.tr(),
                  style: AppTheme.english(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.3,
                  ).copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary,
                    decorationThickness: 1.2,
                  ),
                  recognizer: _qaTap,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ..._hotlines.map(
            (line) {
              final number = line.$2.tr();
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _HotlineRow(
                  flag: line.$1.flag,
                  number: number,
                  onTap: () => _openContactSheet(
                    context,
                    displayNumber: number,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HotlineRow extends StatelessWidget {
  const _HotlineRow({
    required this.flag,
    required this.number,
    required this.onTap,
  });

  final String flag;
  final String number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppStyle.borderRadiusSm,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Spacer(),
            SizedBox(
              width: 22,
              child: Text(
                flag,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, height: 1.1),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 132,
              child: Text(
                number,
                style: AppTheme.english(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                  height: 1.2,
                  letterSpacing: 0.15,
                ).copyWith(
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.primary,
                  decorationThickness: 1.1,
                ),
              ),
            ),
            const Spacer(),
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
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }
}
