import 'package:flutter/material.dart';

import 'shimmer_box.dart';

/// Round placeholder for avatars and icon chips.
class ShimmerCircle extends StatelessWidget {
  const ShimmerCircle({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: size,
      height: size,
      borderRadius: size / 2,
    );
  }
}
