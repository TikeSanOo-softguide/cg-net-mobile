import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

const _danger = Color(0xFFF44336);
const double _dialogRadius = 16;
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

TextStyle _modalBtnText({
  required Color color,
  FontWeight weight = FontWeight.w600,
}) =>
    AppTheme.english(
      fontSize: _modalBtnFontSize,
      fontWeight: weight,
      color: color,
    );

TextStyle _dialogTitleStyle(Color color) => AppTheme.english(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.3,
    );

TextStyle _dialogMessageStyle() => AppTheme.english(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      height: 1.45,
    );

Widget _dialogIcon({
  required IconData icon,
  required Color background,
  required Color foreground,
}) {
  return Container(
    width: 40,
    height: 40,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 20, color: foreground),
  );
}

/// Shared success dialog — primary title + primary icon chip (white glyph).
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
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogIcon(
                icon: LucideIcons.circle_check,
                background: AppColors.primary,
                foreground: AppColors.onPrimary,
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: _dialogTitleStyle(AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: _dialogMessageStyle(),
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

/// Simple alert — primary title + primary icon chip (white glyph).
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
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogIcon(
                icon: LucideIcons.circle_alert,
                background: AppColors.primary,
                foreground: AppColors.onPrimary,
              ),
              if (title != null) ...[
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: _dialogTitleStyle(AppColors.primary),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: _dialogMessageStyle(),
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

/// Shared confirm / danger dialog — red title + red icon chip (white glyph).
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
          borderRadius: BorderRadius.circular(_dialogRadius),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 36),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogIcon(
                icon: LucideIcons.circle_alert,
                background: _danger,
                foreground: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: _dialogTitleStyle(_danger),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                textAlign: TextAlign.center,
                style: _dialogMessageStyle(),
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
                        style: _modalBtnText(
                          color: Colors.white,
                          weight: FontWeight.w700,
                        ),
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
