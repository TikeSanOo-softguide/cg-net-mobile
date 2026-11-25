import 'package:flutter/material.dart';

import 'app_shimmer.dart';
import 'shimmer_config.dart';

/// Rounded placeholder. Animates with the nearest [AppShimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.radius,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final BorderRadius? radius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final box = _ShimmerFill(
      width: width,
      height: height,
      radius: radius ?? BorderRadius.circular(borderRadius),
      baseColor: baseColor,
      highlightColor: highlightColor,
    );
    if (AppShimmer.hasScope(context)) return box;
    return AppShimmer(child: box);
  }
}

class _ShimmerFill extends StatelessWidget {
  const _ShimmerFill({
    required this.width,
    required this.height,
    required this.radius,
    required this.baseColor,
    required this.highlightColor,
  });

  final double? width;
  final double? height;
  final BorderRadius radius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShimmerScope>();
    final brightness = scope?.brightness ?? Theme.of(context).brightness;
    final base = baseColor ?? ShimmerConfig.base(brightness);
    final highlight = highlightColor ?? ShimmerConfig.highlight(brightness);
    final progress = scope?.progress ?? 0;
    final travel = -1.4 + (progress * 2.8);

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment(travel - 0.8, 0),
            end: Alignment(travel + 0.8, 0),
            colors: [base, highlight, base],
          ),
        ),
      ),
    );
  }
}
