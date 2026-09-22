import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// OTP verified confirmation as a bottom drawer (keeps OTP page underneath).
Future<void> showOtpSuccessDrawer(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
  const letterSpacing = 0.0;
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
      return SafeArea(
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                  letterSpacing: letterSpacing,
                ),
              ),
              const SizedBox(height: AppStyle.spaceSm),
              Text(
                'otp.success_body'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                  letterSpacing: letterSpacing,
                  height: AppStyle.lineHeightBody,
                ),
              ),
              const SizedBox(height: AppStyle.spaceXl),
              AppButton(
                label: 'otp.continue_setup'.tr(),
                height: 42,
                fontSize: 13,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onContinue();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
