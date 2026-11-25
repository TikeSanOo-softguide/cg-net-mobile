import 'package:flutter/material.dart';

import '../../core/widgets/shimmer/shimmer.dart';

/// Compact two-column package card. Fills the 232-tall grid cell.
class PackageCardSkeleton extends StatelessWidget {
  const PackageCardSkeleton({super.key});

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
          padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerText(width: 64, height: 16, borderRadius: 6),
              SizedBox(height: 14),
              ShimmerText(width: 52, height: 20),
              SizedBox(height: 16),
              ShimmerText(width: 72, height: 26, borderRadius: 6),
              SizedBox(height: 18),
              ShimmerText(width: 110, height: 10),
              SizedBox(height: 8),
              ShimmerText(width: 84, height: 10),
              Spacer(),
              ShimmerBox(height: 28, borderRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// Package detail: name chip, price, speed, five feature lines, buy button.
class PackageDetailSkeleton extends StatelessWidget {
  const PackageDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        AppShimmer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ShimmerText(width: 88, height: 18, borderRadius: 8),
                      Spacer(),
                      ShimmerText(width: 72, height: 22),
                    ],
                  ),
                  SizedBox(height: 22),
                  ShimmerText(width: 96, height: 28, borderRadius: 6),
                  SizedBox(height: 22),
                  ShimmerText(width: 180, height: 12),
                  SizedBox(height: 12),
                  ShimmerText(width: 150, height: 12),
                  SizedBox(height: 12),
                  ShimmerText(width: 168, height: 12),
                  SizedBox(height: 12),
                  ShimmerText(width: 132, height: 12),
                  SizedBox(height: 12),
                  ShimmerText(width: 156, height: 12),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const AppShimmer(
          child: ShimmerBox(height: 48, borderRadius: 8),
        ),
      ],
    );
  }
}

/// Title card on the package list, shown until products arrive.
class PackageTitleSkeleton extends StatelessWidget {
  const PackageTitleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: ShimmerBox(height: 46, borderRadius: 8),
    );
  }
}
