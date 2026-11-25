import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// Profile account row: logo, name lines, trailing action.
class ProfileHeaderSkeleton extends StatelessWidget {
  const ProfileHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return AppShimmer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card,
          borderRadius: AppStyle.borderRadiusListCard,
        ),
        child: const Padding(
          padding: EdgeInsets.all(AppStyle.spaceMd),
          child: Row(
            children: [
              ShimmerBox(width: 38, height: 38, borderRadius: 8),
              SizedBox(width: AppStyle.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerText(width: 88, height: 11),
                    SizedBox(height: 6),
                    ShimmerText(width: 140, height: 16),
                  ],
                ),
              ),
              SizedBox(width: AppStyle.spaceSm),
              ShimmerBox(width: 32, height: 32, borderRadius: 8),
            ],
          ),
        ),
      ),
    );
  }
}
