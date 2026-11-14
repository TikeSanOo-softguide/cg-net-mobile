import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 96,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.surface,
        child: Container(
          height: itemHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// First-load placeholders that match a card list.
class CardListShimmer extends StatelessWidget {
  const CardListShimmer({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 112,
    this.separator = 2,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 24),
  });

  final int itemCount;
  final double itemHeight;
  final double separator;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: separator),
      itemBuilder: (_, __) => LayoutBuilder(
        builder: (context, constraints) => ShimmerBox(
          width: constraints.maxWidth,
          height: itemHeight,
          borderRadius: borderRadius,
        ),
      ),
    );
  }
}

class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}
