import 'package:flutter/material.dart';

import 'shimmer_box.dart';

/// Short text line. [width] is a logical pixel length.
class ShimmerText extends StatelessWidget {
  const ShimmerText({
    super.key,
    required this.width,
    this.height = 12,
    this.borderRadius = 4,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }
}
