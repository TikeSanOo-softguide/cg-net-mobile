import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_logo/app_logo.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'splash_controller.dart';

/// Splash — vertical: logo (2s) → title words (2s) → subtitle.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _titleWords = ['YOUNG', 'NI', 'OO'];
  static const _subtitle = 'WELCOME';

  /// logo 2s + title 2s + subtitle ~1.6s + short hold
  static const _totalMs = 6000;

  late final AnimationController _controller;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _titleProgress;

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

    // 0.00–0.33 ≈ 2s — logo slow entrance
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.28, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeOutCubic),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.33, curve: Curves.easeOutCubic),
      ),
    );

    // 0.33–0.66 ≈ 2s — title word by word
    _titleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.33, 0.66, curve: Curves.linear),
    );

    // 0.66–0.93 — subtitle: blur clear + elastic + letter-spacing settle
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.88, curve: Curves.easeOut),
    );
    _subtitleScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.93, curve: Curves.elasticOut),
      ),
    );
    _subtitleBlur = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.86, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleLetterSpread = Tween<double>(begin: 8, end: 3.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.66, 0.92, curve: Curves.easeOutCubic),
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

  double _wordOpacity(int index) {
    final t = _titleProgress.value;
    final start = index / _titleWords.length;
    final end = (index + 1) / _titleWords.length;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
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
                    // 1) Logo under center — slow fade + scale + rise (2s)
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
                    const SizedBox(height: 10),

                    // 2) Title under logo — word by word (2s)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < _titleWords.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _TitleWord(
                            word: _titleWords[i],
                            progress: _wordOpacity(i),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 3) Subtitle — blur → sharp + elastic + spacing
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

class _TitleWord extends StatelessWidget {
  const _TitleWord({
    required this.word,
    required this.progress,
  });

  final String word;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final dy = (1 - progress) * 14;
    final scale = 0.86 + (0.14 * progress);

    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          child: Text(
            word,
            style: AppTheme.english(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.onPrimary,
              letterSpacing: 0.8,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}
