import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_logo/app_logo.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'splash_controller.dart';

/// Splash — logo entrance, then static titles (no title animation).
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _titleZh = '晨光产电';
  static const _titleMy = 'မိုင်းလားရောင်နီဦးကုမ္ပဏီ';
  static const _subtitle = 'WELCOME';

  static const _totalMs = 4200;

  late final AnimationController _controller;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _subtitleScale;
  late final Animation<double> _subtitleBlur;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleLetterSpread;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.58, 0.82, curve: Curves.easeOut),
    );
    _subtitleScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.88, curve: Curves.elasticOut),
      ),
    );
    _subtitleBlur = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.80, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.82, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleLetterSpread = Tween<double>(begin: 8, end: 3.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.58, 0.86, curve: Curves.easeOutCubic),
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
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SlideTransition(
                      position: _logoSlide,
                      child: FadeTransition(
                        opacity: _logoOpacity,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: const AppLogo(
                            width: 100,
                            height: 65,
                            padding: 0,
                            borderRadius: 0,
                            backgroundColor: Colors.transparent,
                            showShadow: false,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Static titles — golden linear gradient, no motion.
                    _GoldenTitle(
                      text: _titleZh,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                    const SizedBox(height: 8),
                    _GoldenTitle(
                      text: _titleMy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 14),
                    SlideTransition(
                      position: _subtitleSlide,
                      child: FadeTransition(
                        opacity: _subtitleOpacity,
                        child: ScaleTransition(
                          scale: _subtitleScale,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(
                              sigmaX: _subtitleBlur.value,
                              sigmaY: _subtitleBlur.value,
                            ),
                            child: Text(
                              _subtitle,
                              style: AppTheme.english(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.onPrimary
                                    .withValues(alpha: 0.9),
                                letterSpacing: _subtitleLetterSpread.value,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GoldenTitle extends StatelessWidget {
  const _GoldenTitle({
    required this.text,
    required this.fontSize,
    required this.fontWeight,
    this.letterSpacing,
  });

  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;

  static const _goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFF8DC), // cornsilk
      Color(0xFFFFE082), // soft gold
      Color(0xFFFFD54F), // amber
      Color(0xFFFFC107), // primary gold
      Color(0xFFB8860B), // dark goldenrod
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => _goldGradient.createShader(bounds),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.english(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
          letterSpacing: letterSpacing,
          height: 1.3,
        ),
      ),
    );
  }
}
