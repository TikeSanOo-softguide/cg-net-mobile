import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_logo/app_logo.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import 'splash_controller.dart';

/// Splash — logo, then titles word-by-word with metallic gold gradient.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _titleZhWords = ['晨光', '产电'];
  static const _titleMyWords = ['မိုင်းလား', 'ရောင်နီဦး', 'ကုမ္ပဏီ'];

  /// logo ~1.4s + titles ~2.4s
  static const _totalMs = 4000;

  late final AnimationController _controller;

  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _logoSlide;

  late final Animation<double> _titleZhProgress;
  late final Animation<double> _titleMyProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    // 0.00–0.28 logo
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOutCubic),
      ),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.28, curve: Curves.easeOutCubic),
      ),
    );

    // 0.28–0.64 Chinese title word by word
    _titleZhProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.64, curve: Curves.linear),
    );

    // 0.56–1.00 Myanmar title word by word
    _titleMyProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.56, 1.00, curve: Curves.linear),
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

  double _wordProgress(Animation<double> animation, int index, int count) {
    final t = animation.value;
    final start = index / count;
    final end = (index + 1) / count;
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                    // No gap between logo and title.
                    SizedBox(
                      width: double.infinity,
                      child: _WordRow(
                        words: _titleZhWords,
                        progressFor: (i) => _wordProgress(
                          _titleZhProgress,
                          i,
                          _titleZhWords.length,
                        ),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        wordGap: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: _WordRow(
                        words: _titleMyWords,
                        progressFor: (i) => _wordProgress(
                          _titleMyProgress,
                          i,
                          _titleMyWords.length,
                        ),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        wordGap: 6,
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

class _WordRow extends StatelessWidget {
  const _WordRow({
    required this.words,
    required this.progressFor,
    required this.fontSize,
    required this.fontWeight,
    this.letterSpacing,
    this.wordGap = 8,
  });

  final List<String> words;
  final double Function(int index) progressFor;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;
  final double wordGap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < words.length; i++) ...[
          if (i > 0) SizedBox(width: wordGap),
          _GoldenWord(
            word: words[i],
            progress: progressFor(i),
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: letterSpacing,
          ),
        ],
      ],
    );
  }
}

class _GoldenWord extends StatelessWidget {
  const _GoldenWord({
    required this.word,
    required this.progress,
    required this.fontSize,
    required this.fontWeight,
    this.letterSpacing,
  });

  final String word;
  final double progress;
  final double fontSize;
  final FontWeight fontWeight;
  final double? letterSpacing;

  static const _goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF6C8),
      Color(0xFFFFEE13),
      Color(0xFFD4AF37),
      Color(0xFFB8860B),
      Color(0xFFF3D774),
    ],
    stops: [0.0, 0.22, 0.48, 0.78, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final dy = (1 - progress) * 10;
    final scale = 0.88 + (0.12 * progress);

    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(0, dy),
        child: Transform.scale(
          scale: scale,
          child: ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => _goldGradient.createShader(bounds),
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: AppTheme.english(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: Colors.white,
                letterSpacing: letterSpacing,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
