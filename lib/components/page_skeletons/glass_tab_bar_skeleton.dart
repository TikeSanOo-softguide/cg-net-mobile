import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// Placeholder for [AppGlassTabBar] until the list has data.
class GlassTabBarSkeleton extends StatelessWidget {
  const GlassTabBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ShimmerBox(
        height: 50,
        borderRadius: AppStyle.radiusListCard,
      ),
    );
  }
}
