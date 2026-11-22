import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// Inbox row: category icon, title and date, two-line body.
class InboxListSkeleton extends StatelessWidget {
  const InboxListSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (_, __) => const _InboxRow(),
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow();

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
                          child: ShimmerText(width: 140, height: 16),
                        ),
                      ),
                      SizedBox(width: 8),
                      ShimmerText(width: 36, height: 10),
                    ],
                  ),
                  SizedBox(height: 8),
                  ShimmerText(width: 200, height: 12),
                  SizedBox(height: 6),
                  ShimmerText(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
