import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// About: version card (title, number, three info lines) and release notes.
class AboutVersionSkeleton extends StatelessWidget {
  const AboutVersionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(AppStyle.radiusLg),
            ),
            child: const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerText(width: 110, height: 12),
                  SizedBox(height: 12),
                  ShimmerText(width: 72, height: 22, borderRadius: 6),
                  SizedBox(height: 12),
                  ShimmerText(width: 150, height: 12),
                  SizedBox(height: 16),
                  _Info(),
                  SizedBox(height: 12),
                  _Info(),
                  SizedBox(height: 12),
                  _Info(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(AppStyle.radiusLg),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerText(width: 120, height: 15),
                  SizedBox(height: 14),
                  ShimmerText(width: 240, height: 12),
                  SizedBox(height: 10),
                  ShimmerText(width: 200, height: 12),
                  SizedBox(height: 10),
                  ShimmerText(width: 168, height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerText(width: 96, height: 12),
        Spacer(),
        ShimmerText(width: 64, height: 12),
      ],
    );
  }
}
