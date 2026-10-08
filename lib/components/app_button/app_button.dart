import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Solid primary CTA — background exactly `#0100CA`, white label, no overlays.
///
/// Locale-stable: fixed [height], single-line label with gentle scale-down so
/// EN / MY / ZH text swaps never change button size or layout.
/// When [onPressed] is null or [isLoading], shows a muted disabled style.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isExpanded = true,
    this.icon,
    this.height = 45,
    this.fontSize = 14,
    this.disabledColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isExpanded;
  final IconData? icon;
  final double height;
  final double fontSize;
  final Color? disabledColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final buttonColor = !enabled && !isLoading
        ? disabledColor ?? AppColors.primary
        : AppColors.primary;

    final child = isLoading
        ? SizedBox(
            height: fontSize + 4,
            width: fontSize + 4,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: foreground,
            ),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: fontSize + 2,
                    color: foreground,
                  ),
                  const SizedBox(width: AppStyle.spaceSm),
                ],
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: labelStyle,
                ),
              ],
            ),
          );

    final button = GestureDetector(
      onTap: enabled ? onPressed : null,
      child: ClipRRect(
        borderRadius: AppStyle.borderRadiusButton,
        child: ColoredBox(
          color: buttonColor,
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
    return SizedBox(width: double.infinity, height: height, child: button);
  }
}
