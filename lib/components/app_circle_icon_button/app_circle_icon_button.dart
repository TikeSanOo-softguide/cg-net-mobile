import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Top-bar icon — square with small radius (default 6), white glyph.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = AppStyle.circleButtonSize,
    this.iconSize = 16,
    this.backgroundColor,
    this.borderRadius = 6,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.onPrimary,
          backgroundColor: backgroundColor ?? Colors.transparent,
          disabledForegroundColor: AppColors.onPrimary,
          overlayColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size(size, size),
          maximumSize: Size(size, size),
          padding: EdgeInsets.zero,
          shape: shape,
        ),
        icon: Icon(
          icon,
          size: iconSize,
          color: AppColors.onPrimary,
        ),
      ),
    );
  }
}
