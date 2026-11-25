import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Compact processing mark on a dimmed screen.
///
/// Three dots take turns growing and brightening. [Material] stays
/// transparent so the dialog does not paint Flutter's double yellow debug
/// underline.
class ProcessingStatus extends StatelessWidget {
  const ProcessingStatus({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                color: AppColors.primaryLight.withValues(alpha: 0.55),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _ProcessingDots(),
                    const SizedBox(height: 6),
                    _ShimmerLabel(label: label),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerLabel extends StatefulWidget {
  const _ShimmerLabel({required this.label});

  final String label;

  @override
  State<_ShimmerLabel> createState() => _ShimmerLabelState();
}

class _ShimmerLabelState extends State<_ShimmerLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTheme.english(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
      height: 1,
    ).copyWith(decoration: TextDecoration.none);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final slide = -1.4 + (_controller.value * 2.8);
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(slide, 0),
              end: Alignment(slide + 1.1, 0),
              colors: const [
                Color(0x8C0100CA),
                Color(0xFF0100CA),
                Color(0x8C0100CA),
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.label,
        textAlign: TextAlign.center,
        style: style,
      ),
    );
  }
}

class _ProcessingDots extends StatefulWidget {
  const _ProcessingDots();

  @override
  State<_ProcessingDots> createState() => _ProcessingDotsState();
}

class _ProcessingDotsState extends State<_ProcessingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _pulse(int index) {
    const stagger = 0.16;
    const width = 0.42;
    var local = _controller.value - (index * stagger);
    local %= 1;
    if (local < 0) local += 1;
    if (local > width) return 0;
    return math.sin((local / width) * math.pi);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              _Dot(t: _pulse(i)),
            ],
          ],
        );
      },
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    final size = 5 + (3 * t);
    return SizedBox(
      width: 8,
      height: 8,
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.22 + (0.78 * t)),
            shape: BoxShape.circle,
          ),
          child: SizedBox.square(dimension: size),
        ),
      ),
    );
  }
}
