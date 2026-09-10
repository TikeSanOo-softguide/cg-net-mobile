import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';

/// Shared CG-NET logo: primary background + original logo colors (no tint).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 44,
    this.padding = 6,
    this.borderRadius = 12,
    this.backgroundColor = AppColors.primary,
    this.showShadow = false,
  });

  final double size;
  final double padding;
  final double borderRadius;
  final Color backgroundColor;
  final bool showShadow;

  static const assetPath = 'assets/images/cg_net_logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
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
