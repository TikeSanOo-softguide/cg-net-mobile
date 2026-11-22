import 'package:flutter/material.dart';

import '../../core/widgets/shimmer/shimmer.dart';

/// Home plan card: line chip, price, speed, two features. Height 152.
class HomePackageCardSkeleton extends StatelessWidget {
  const HomePackageCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return AppShimmer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerText(width: 72, height: 18, borderRadius: 8),
                  Spacer(),
                  ShimmerText(width: 64, height: 22),
                ],
              ),
              SizedBox(height: 18),
              ShimmerText(width: 88, height: 28, borderRadius: 6),
              SizedBox(height: 16),
              ShimmerText(width: 140, height: 10),
              SizedBox(height: 8),
              ShimmerText(width: 108, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home offer card: 16:9 image, title, two description lines, action.
class HomeOfferCardSkeleton extends StatelessWidget {
  const HomeOfferCardSkeleton({super.key, required this.imageHeight});

  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return AppShimmer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(
              height: imageHeight,
              radius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerText(width: 120, height: 14),
                  SizedBox(height: 8),
                  ShimmerText(width: 160, height: 10),
                  SizedBox(height: 6),
                  ShimmerText(width: 96, height: 10),
                  SizedBox(height: 14),
                  ShimmerText(width: 64, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
