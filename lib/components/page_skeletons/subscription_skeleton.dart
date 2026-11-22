import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// Subscription plan: title row, then valid-until, remaining, username, password.
class SubscriptionListSkeleton extends StatelessWidget {
  const SubscriptionListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 2,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => const _PlanCard(),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppStyle.borderRadiusListCard,
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ShimmerBox(width: 26, height: 26, borderRadius: 7),
                SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ShimmerText(width: 140, height: 14),
                  ),
                ),
                SizedBox(width: 8),
                ShimmerText(width: 56, height: 18, borderRadius: 8),
              ],
            ),
            SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFF4F6FB),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    _Line(),
                    SizedBox(height: 12),
                    _Line(),
                    SizedBox(height: 12),
                    _Line(),
                    SizedBox(height: 12),
                    _Line(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerText(width: 72, height: 12),
        Spacer(),
        ShimmerText(width: 96, height: 12),
      ],
    );
  }
}
