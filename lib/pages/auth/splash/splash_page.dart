import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_logo/app_logo.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import 'splash_controller.dart';

/// Splash: solid `#0100CA` (matches native launch) → logo fade/scale → app.
/// Primary blue is never tweened into another shade.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _totalDuration = Duration(milliseconds: 2800);

  late final AnimationController _controller;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.55, curve: Curves.easeInOut),
    );
    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.12, 0.62, curve: Curves.easeInOutCubic),
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
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return ColoredBox(
            color: AppColors.primary,
            child: Center(
              child: Opacity(
                opacity: _logoOpacity.value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: const AppLogo(
                    size: 160,
                    padding: 20,
                    borderRadius: 28,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
