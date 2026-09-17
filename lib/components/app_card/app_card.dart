import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Shared flat card — white surface, no border / shadow.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppStyle.cardPadding,
    this.margin,
    this.onTap,
    this.elevated = false,
    this.bordered = true,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool elevated;

  /// Kept for call-site compatibility. Cards stay flat (no edge).
  final bool bordered;
  final Color? color;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppStyle.borderRadiusSm;
    final decoration = BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: radius,
    );

    final content = Padding(padding: padding, child: child);

    return Container(
      margin: margin,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                splashColor: Colors.black.withValues(alpha: 0.06),
                highlightColor: Colors.black.withValues(alpha: 0.04),
                child: content,
              ),
            ),
    );
  }
}
