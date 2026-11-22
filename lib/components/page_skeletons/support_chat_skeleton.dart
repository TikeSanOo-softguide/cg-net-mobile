import 'package:flutter/material.dart';

import '../../core/widgets/shimmer/shimmer.dart';

/// Support thread: incoming bubbles on the left, replies on the right.
class SupportChatSkeleton extends StatelessWidget {
  const SupportChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        Widget bubble(double factor, double height, {required bool mine}) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Align(
              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
              child: ShimmerBox(
                width: width * factor,
                height: height,
                borderRadius: 10,
              ),
            ),
          );
        }

        return AppShimmer(
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            children: [
              bubble(0.72, 72, mine: false),
              bubble(0.46, 44, mine: true),
              bubble(0.64, 64, mine: false),
              bubble(0.38, 44, mine: true),
            ],
          ),
        );
      },
    );
  }
}
