import 'package:flutter/material.dart';

import 'shimmer_config.dart';

/// One sweep shared by every placeholder under this widget.
class AppShimmer extends StatefulWidget {
  const AppShimmer({super.key, required this.child});

  final Widget child;

  static bool hasScope(BuildContext context) {
    return context.getElementForInheritedWidgetOfExactType<ShimmerScope>() !=
        null;
  }

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(vsync: this, duration: ShimmerConfig.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (context, child) {
        return ShimmerScope(
          progress: _motion.value,
          brightness: Theme.of(context).brightness,
          child: child!,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerScope extends InheritedWidget {
  const ShimmerScope({
    super.key,
    required this.progress,
    required this.brightness,
    required super.child,
  });

  final double progress;
  final Brightness brightness;

  @override
  bool updateShouldNotify(ShimmerScope oldWidget) {
    return oldWidget.progress != progress || oldWidget.brightness != brightness;
  }
}
