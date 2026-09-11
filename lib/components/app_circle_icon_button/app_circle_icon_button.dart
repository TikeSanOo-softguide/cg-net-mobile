import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Top-bar icon — pure primary bar, white glyph only (no glass / border / shadow).
/// Same idea as bottom-nav: flat icon color, no light fill overlay.
class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = AppStyle.circleButtonSize,
    this.iconSize = AppStyle.iconSizeSm,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.onPrimary,
          backgroundColor: Colors.transparent,
          disabledForegroundColor: AppColors.onPrimary,
          overlayColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size(size, size),
          maximumSize: Size(size, size),
          padding: EdgeInsets.zero,
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
