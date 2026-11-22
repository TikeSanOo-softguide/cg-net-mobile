import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// History row: 38 icon, title and amount, two-line body, date.
class HistoryListSkeleton extends StatelessWidget {
  const HistoryListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (_, __) => const _ActivityRow(),
      ),
    );
  }
}

/// Service history uses the same row, always the bill icon and a debit amount.
class ServiceHistoryListSkeleton extends StatelessWidget {
  const ServiceHistoryListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const HistoryListSkeleton();
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow();

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: card,
        borderRadius: AppStyle.borderRadiusListCard,
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: 38, height: 38, borderRadius: 8),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ShimmerText(width: 120, height: 14),
                        ),
                      ),
                      SizedBox(width: 8),
                      ShimmerText(width: 64, height: 12),
                    ],
                  ),
                  SizedBox(height: 8),
                  ShimmerText(width: 180, height: 12),
                  SizedBox(height: 6),
                  ShimmerText(width: 96, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
