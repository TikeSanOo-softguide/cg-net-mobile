import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// OTP verified confirmation as a bottom drawer (keeps OTP page underneath).
///
/// Not dismissible by drag, barrier tap, or system back — only Continue.
/// [onContinue] should navigate with `goNamed` (replaces the route so the
/// sheet goes away with the page; no separate pop → no OTP flash).
Future<void> showOtpSuccessDrawer(
  BuildContext context, {
  required Future<void> Function() onContinue,
}) {
  const iconBox = 45.0;
  const iconSize = 26.0;
  const iconRadius = 10.0;
  // Soft wash of success #499A13
  const successChip = Color(0xFFE8F5DC);

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppStyle.radiusCurve),
      ),
    ),
    builder: (sheetContext) {
      final titleSize = authTitleFontSize(sheetContext);
      final subtitleSize = authSubtitleFontSize(sheetContext);

      return PopScope(
        canPop: false,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppStyle.spaceXl),
                Center(
                  child: Container(
                    width: iconBox,
                    height: iconBox,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: successChip,
                      borderRadius: BorderRadius.circular(iconRadius),
                    ),
                    child: const Image(
                      image: AssetImage('assets/images/dialogs/success.png'),
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
                const SizedBox(height: AppStyle.spaceLg),
                Text(
                  'otp.success_title'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                    letterSpacing: 0.2,
                    height: AppStyle.lineHeightTitle,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'otp.success_body'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppStyle.spaceXl),
                _ContinueButton(onContinue: onContinue),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _ContinueButton extends StatefulWidget {
  const _ContinueButton({required this.onContinue});

  final Future<void> Function() onContinue;

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _busy = false;

  Future<void> _handle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onContinue();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: 'otp.continue_setup'.tr(),
      height: 44,
      fontSize: 14,
      isLoading: _busy,
      onPressed: _busy ? null : () { _handle(); },
    );
  }
}
