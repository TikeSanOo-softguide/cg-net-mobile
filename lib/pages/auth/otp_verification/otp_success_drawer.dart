import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_button/app_button.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// OTP verified confirmation as a bottom drawer (keeps OTP page underneath).
Future<void> showOtpSuccessDrawer(
  BuildContext context, {
  required VoidCallback onContinue,
}) {
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
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.circle_check,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppStyle.spaceLg),
              Text(
                'otp.success_title'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppStyle.spaceSm),
              Text(
                'otp.success_body'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.bodySecondary(),
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
