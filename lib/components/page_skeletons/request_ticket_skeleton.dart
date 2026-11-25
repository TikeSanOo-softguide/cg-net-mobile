import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// Request list card that opens a detail page: ticket, actions, date, status.
class RequestTicketListSkeleton extends StatelessWidget {
  const RequestTicketListSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppStyle.spaceLg,
          AppStyle.spaceLg,
          AppStyle.spaceLg,
          AppStyle.listPaddingAboveFab,
        ),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 2),
        itemBuilder: (_, __) => const _Ticket(),
      ),
    );
  }
}

class _Ticket extends StatelessWidget {
  const _Ticket();

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerText(width: 72, height: 10),
                      SizedBox(height: 6),
                      ShimmerText(width: 120, height: 14),
                    ],
                  ),
                ),
                ShimmerBox(width: 26, height: 24, borderRadius: 6),
                SizedBox(width: 8),
                ShimmerBox(width: 26, height: 24, borderRadius: 6),
              ],
            ),
            SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: ShimmerText(width: 88, height: 12)),
                ShimmerText(width: 64, height: 18, borderRadius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
