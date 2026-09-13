import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';

/// Shared CG-NET logo: original logo colors (no tint).
///
/// The artwork is wider than tall, so [width]/[height] can be set when the
/// surrounding surface should hug the mark instead of using a square box.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 44,
    this.width,
    this.height,
    this.padding = 6,
    this.borderRadius = 12,
    this.backgroundColor = AppColors.primary,
    this.borderColor,
    this.showShadow = false,
  });

  final double size;
  final double? width;
  final double? height;
  final double padding;
  final double borderRadius;
  final Color backgroundColor;
  final Color? borderColor;
  final bool showShadow;

  static const assetPath = 'assets/images/cg_net_logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? size,
      height: height ?? size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
