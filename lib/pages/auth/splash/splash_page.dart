import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import 'splash_controller.dart';

/// Premium circular-reveal splash: white → expanding #0100CA → logo → app.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 4200);

  late final AnimationController _controller;
  late final Animation<double> _circleExpand;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    // Brief pause with a tiny circle, then a slow full-screen expand.
    _circleExpand = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.06, 0.62, curve: Curves.easeInOutCubic),
    );

    // Soft fade + gentle scale after blue fills the screen.
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 0.82, curve: Curves.easeInOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.86, curve: Curves.easeInOutCubic),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        ref.read(splashControllerProvider.notifier).bootstrap(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Radius that covers the farthest screen corner from center.
    final maxRadius =
        math.sqrt(math.pow(size.width / 2, 2) + math.pow(size.height / 2, 2));

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          // Keep a tiny visible start so the circle "appears", then expand.
          final t = _circleExpand.value;
          final radius = math.max(4.0, maxRadius * t);

          return Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.white),
              ClipPath(
                clipper: _CircleRevealClipper(radius: radius),
                child: const ColoredBox(color: AppColors.primary),
              ),
              Center(
                child: Opacity(
                  opacity: _logoOpacity.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: Image.asset(
                      'assets/images/cg_net_logo.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CircleRevealClipper extends CustomClipper<Path> {
  const _CircleRevealClipper({required this.radius});

  final double radius;

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _CircleRevealClipper oldClipper) {
    return oldClipper.radius != radius;
  }
}
