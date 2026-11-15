import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';

/// Small ring of rounded bars. The bright bar chases around the circle.
class AppSpinner extends StatefulWidget {
  const AppSpinner({
    super.key,
    this.size = 24,
    this.color = AppColors.primary,
    this.barCount = 12,
  });

  final double size;
  final Color color;
  final int barCount;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BarSpinnerPainter(
              progress: _controller.value,
              color: widget.color,
              barCount: widget.barCount,
            ),
          );
        },
      ),
    );
  }
}

class _BarSpinnerPainter extends CustomPainter {
  const _BarSpinnerPainter({
    required this.progress,
    required this.color,
    required this.barCount,
  });

  final double progress;
  final Color color;
  final int barCount;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final barWidth = size.shortestSide * 0.085;
    final barLength = size.shortestSide * 0.28;
    final orbit = size.shortestSide * 0.32;
    final head = (progress * barCount).floor();

    for (var i = 0; i < barCount; i++) {
      final stepsBehind = (head - i + barCount) % barCount;
      final opacity = 1 - (stepsBehind / barCount);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.16 + (0.84 * opacity))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((math.pi * 2 * i) / barCount);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(0, -orbit),
            width: barWidth,
            height: barLength,
          ),
          Radius.circular(barWidth),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BarSpinnerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.barCount != barCount;
  }
}
