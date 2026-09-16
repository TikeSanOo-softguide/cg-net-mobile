import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Soft chip wash — same recipe as home Pay Bill icon chip.
Color _primaryChipBackground() =>
    Color.alphaBlend(AppColors.primary.withValues(alpha: 0.10), Colors.white);

const _danger = Color(0xFFF44336);
Color _dangerLight() =>
    Color.alphaBlend(_danger.withValues(alpha: 0.10), Colors.white);

const double _modalBtnHeight = 32;
const double _modalBtnMinWidth = 120;
const double _modalBtnFontSize = 11;

ButtonStyle _primaryModalBtnStyle() => FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      elevation: 0,
      minimumSize: const Size(_modalBtnMinWidth, _modalBtnHeight),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusInput),
      ),
    );

ButtonStyle _dangerModalBtnStyle() => FilledButton.styleFrom(
      backgroundColor: _danger,
      foregroundColor: Colors.white,
      elevation: 0,
      minimumSize: const Size(_modalBtnMinWidth, _modalBtnHeight),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyle.radiusInput),
      ),
    );

TextStyle _modalBtnText({required Color color, FontWeight weight = FontWeight.w600}) =>
    AppTheme.english(
      fontSize: _modalBtnFontSize,
      fontWeight: weight,
      color: color,
    );

/// Shared success dialog — white card, primary chip-style icon wash.
Future<void> showAppSuccessModal(
  BuildContext context, {
  required String title,
  required String body,
  String? buttonLabel,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyle.radiusXl),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryChipBackground(),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.circle_check,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTheme.bodySecondary().copyWith(fontSize: 13),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.done'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Simple alert — message + single OK (no secondary action).
Future<void> showAppAlertModal(
  BuildContext context, {
  required String message,
  String? buttonLabel,
  String? title,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyle.radiusXl),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryChipBackground(),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.circle_alert,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.english(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTheme.bodySecondary().copyWith(fontSize: 13),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: _modalBtnHeight,
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: _primaryModalBtnStyle(),
                  child: Text(
                    buttonLabel ?? 'common.ok'.tr(),
                    style: _modalBtnText(color: AppColors.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shared confirm dialog — white card, danger icon wash, compact buttons.
Future<bool> showAppConfirmModal(
  BuildContext context, {
  required String title,
  required String body,
  String? confirmLabel,
  String? cancelLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyle.radiusXl),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _dangerLight(),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.circle_alert,
                  size: 18,
                  color: _danger,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTheme.english(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppTheme.bodySecondary().copyWith(fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: _modalBtnHeight,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(false),
                      style: _dangerModalBtnStyle(),
                      child: Text(
                        cancelLabel ?? 'common.cancel'.tr(),
                        style: _modalBtnText(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: _modalBtnHeight,
                    child: FilledButton(
                      onPressed: () =>
                          Navigator.of(dialogContext).pop(true),
                      style: _primaryModalBtnStyle(),
                      child: Text(
                        confirmLabel ?? 'common.confirm'.tr(),
                        style: _modalBtnText(
                          color: AppColors.onPrimary,
                          weight: FontWeight.w700,
                        ),
                      ),
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
  return result == true;
}
