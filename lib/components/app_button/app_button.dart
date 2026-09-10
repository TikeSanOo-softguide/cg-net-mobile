import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, accent }

/// Common full-width CTA button with optional leading icon + loading state.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: AppStyle.iconSizeSm,
            width: AppStyle.iconSizeSm,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: _spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppStyle.iconSizeSm),
                const SizedBox(width: AppStyle.spaceSm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: AppStyle.borderRadiusButton,
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(AppStyle.controlHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppStyle.spaceLg),
            shape: shape,
            textStyle: _labelStyle,
          ),
          child: child,
        ),
      AppButtonVariant.secondary => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(AppStyle.controlHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppStyle.spaceLg),
            shape: shape,
            textStyle: _labelStyle,
          ),
          child: child,
        ),
      AppButtonVariant.accent => FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            minimumSize: const Size.fromHeight(AppStyle.controlHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppStyle.spaceLg),
            shape: shape,
            textStyle: _labelStyle,
          ),
          child: child,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(AppStyle.controlHeight),
            padding: const EdgeInsets.symmetric(horizontal: AppStyle.spaceLg),
            side: AppStyle.borderSideFocus,
            shape: shape,
            textStyle: _labelStyle,
          ),
          child: child,
        ),
    };

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }

  Color get _spinnerColor => switch (variant) {
        AppButtonVariant.accent => AppColors.onAccent,
        AppButtonVariant.secondary => AppColors.primary,
        AppButtonVariant.outline => AppColors.primary,
        AppButtonVariant.primary => AppColors.onPrimary,
      };

  TextStyle get _labelStyle => AppTheme.button();
}
