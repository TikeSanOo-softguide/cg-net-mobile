import 'package:flutter/material.dart';

import '../../core/theme/app_style/app_style.dart';
import '../../core/widgets/shimmer/shimmer.dart';

/// Show room card: office chip and name, address, two phones, chat icons.
class ShowRoomListSkeleton extends StatelessWidget {
  const ShowRoomListSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppStyle.listPaddingBottom),
        itemCount: itemCount,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const _ShowRoomCard(),
      ),
    );
  }
}

class _ShowRoomCard extends StatelessWidget {
  const _ShowRoomCard();

  @override
  Widget build(BuildContext context) {
    final card = ShimmerConfig.card(Theme.of(context).brightness);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ShimmerBox(width: 22, height: 22, borderRadius: 6),
                SizedBox(width: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ShimmerText(width: 140, height: 14),
                  ),
                ),
                SizedBox(width: 6),
                ShimmerCircle(size: 22),
              ],
            ),
            SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerCircle(size: 14),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerText(width: 220, height: 12),
                      SizedBox(height: 6),
                      ShimmerText(width: 160, height: 12),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                SizedBox(width: 10),
                ShimmerText(width: 110, height: 14),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                ShimmerBox(width: 16, height: 16, borderRadius: 4),
                SizedBox(width: 10),
                ShimmerText(width: 110, height: 14),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                ShimmerCircle(size: 28),
                SizedBox(width: 8),
                ShimmerCircle(size: 28),
                SizedBox(width: 8),
                ShimmerCircle(size: 28),
                SizedBox(width: 8),
                ShimmerCircle(size: 28),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
