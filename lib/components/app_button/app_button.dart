import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Solid primary CTA — background exactly `#0100CA`, white label, no overlays.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.height = 42,
    this.fontSize = 13,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    final child = isLoading
        ? SizedBox(
            height: fontSize + 4,
            width: fontSize + 4,
            child: const CircularProgressIndicator(
              strokeWidth: 2.2,
              color: AppColors.onPrimary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: fontSize + 2,
                  color: AppColors.onPrimary,
                ),
                const SizedBox(width: AppStyle.spaceSm),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.button(color: AppColors.onPrimary).copyWith(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    final button = GestureDetector(
      onTap: enabled ? onPressed : null,
      child: ClipRRect(
        borderRadius: AppStyle.borderRadiusButton,
        child: ColoredBox(
          color: AppColors.primary,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppStyle.spaceLg),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );

    if (!isExpanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}
