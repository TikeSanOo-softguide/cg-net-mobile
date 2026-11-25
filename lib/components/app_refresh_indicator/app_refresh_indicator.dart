import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_status.dart';
import '../../core/network/server_availability.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../app_spinner/app_spinner.dart';
import '../network_status_host/network_status_host.dart';

/// Pull-to-refresh with one distance on every phone.
///
/// The mark follows the finger and fills across 80 logical pixels. Releasing
/// sooner puts it back. Releasing past that distance runs [onRefresh] and
/// shows [AppSpinner]. Android reports the pull as overscroll. iOS reports it
/// as a bounce. Both are counted. [edgeOffset] only moves the mark down, for
/// a pinned header. It does not change the 80-pixel distance.
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
    this.color = AppColors.primary,
    this.recoveryKey,
  });

  static const triggerDistance = 80.0;

  final RefreshCallback onRefresh;
  final Widget child;
  final double edgeOffset;
  final Color color;

  /// Reloaded when the server comes back after this pull failed to reach it.
  final String? recoveryKey;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator>
    with SingleTickerProviderStateMixin {
  static const _rest = 16.0;
  static const _visibleAfter = 8.0;

  late final AnimationController _motion;

  double _drag = 0;
  double _offset = 0;
  double _motionFrom = 0;
  double _motionTo = 0;
  var _motionGeneration = 0;
  var _tracking = false;
  var _refreshing = false;
  var _animating = false;
  var _ticked = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (!mounted || !_animating) return;
        setState(() {
          _offset = _motionFrom + (_motionTo - _motionFrom) * _motion.value;
        });
      });
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || _refreshing) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails == null || !_atLeadingEdge(notification)) {
        return false;
      }
      _motionGeneration++;
      _animating = false;
      _motion.stop();
      _tracking = true;
      _drag = 0;
      _ticked = false;
      if (_offset != 0) setState(() => _offset = 0);
      return false;
    }

    if (!_tracking) return false;

    if (notification is ScrollUpdateNotification) {
      _apply(notification.metrics.axisDirection, notification.scrollDelta ?? 0);
    } else if (notification is OverscrollNotification) {
      _apply(notification.metrics.axisDirection, notification.overscroll);
    } else if (notification is ScrollEndNotification) {
      _endDrag();
    }
    return false;
  }

  bool _atLeadingEdge(ScrollNotification notification) {
    final metrics = notification.metrics;
    return switch (metrics.axisDirection) {
      AxisDirection.down => metrics.extentBefore <= 0,
      AxisDirection.up => metrics.extentAfter <= 0,
      AxisDirection.left || AxisDirection.right => false,
    };
  }

  void _apply(AxisDirection direction, double raw) {
    final pulled = switch (direction) {
      AxisDirection.down => -raw,
      AxisDirection.up => raw,
      AxisDirection.left || AxisDirection.right => 0.0,
    };
    final next = math.max(0.0, _drag + pulled);
    if ((next - _drag).abs() < 0.4) return;
    final crossed = next >= AppRefreshIndicator.triggerDistance;
    if (crossed && !_ticked) {
      _ticked = true;
      HapticFeedback.selectionClick();
    } else if (!crossed) {
      _ticked = false;
    }
    _drag = next;
    _motionGeneration++;
    _animating = false;
    _motion.stop();
    setState(
      () => _offset = math.min(next, AppRefreshIndicator.triggerDistance),
    );
  }

  void _endDrag() {
    if (!_tracking) return;
    _tracking = false;
    final pulled = _drag;
    _drag = 0;
    _ticked = false;
    if (pulled >= AppRefreshIndicator.triggerDistance) {
      _startRefresh();
      return;
    }
    if (_offset > 0) _moveOffset(0);
  }

  void _startRefresh() {
    setState(() => _refreshing = true);
    _moveOffset(_rest);
    unawaited(_finishRefresh());
  }

  Future<void> _finishRefresh() async {
    try {
      await widget.onRefresh();
    } catch (_) {}
    if (!mounted) return;
    if (NetworkStatusSnapshot.current == NetworkStatus.offline) {
      GlobalOfflineNotice.show();
    } else if (BackendStatusSnapshot.current == BackendStatus.unavailable) {
      GlobalServerNotice.showDown();
      final key = widget.recoveryKey;
      if (key != null) {
        ProviderScope.containerOf(context)
            .read(serverListRecoveryProvider)
            .arm(key, () => widget.onRefresh());
      }
    }
    if (!mounted) return;
    _motionGeneration++;
    _animating = false;
    _motion.stop();
    setState(() {
      _refreshing = false;
      _offset = 0;
    });
  }

  void _moveOffset(double to) {
    final generation = ++_motionGeneration;
    _motionFrom = _offset;
    _motionTo = to;
    _animating = true;
    _motion.forward(from: 0).whenComplete(() {
      if (generation != _motionGeneration) return;
      _animating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showMark = !_refreshing && _offset >= _visibleAfter;
    final showSpinner = _refreshing;
    final progress =
        (_offset / AppRefreshIndicator.triggerDistance).clamp(0.0, 1.0);

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.child,
        ),
        if (showMark || showSpinner)
          Positioned(
            top: widget.edgeOffset + _offset,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: showSpinner
                    ? AppSpinner(size: 28, color: widget.color)
                    : _PullMark(progress: progress, color: widget.color),
              ),
            ),
          ),
      ],
    );
  }
}

class _PullMark extends StatelessWidget {
  const _PullMark({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 0.72 + (0.28 * progress),
      child: SizedBox(
        width: 22,
        height: 22,
        child: CustomPaint(
          painter: _PullMarkPainter(progress: progress, color: color),
        ),
      ),
    );
  }
}

class _PullMarkPainter extends CustomPainter {
  const _PullMarkPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 8;
    final center = Offset(size.width / 2, size.height / 2);
    final barWidth = size.shortestSide * 0.11;
    final barLength = size.shortestSide * 0.30;
    final orbit = size.shortestSide * 0.30;
    final lit = progress * barCount;

    for (var i = 0; i < barCount; i++) {
      final amount = (lit - i).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = color.withValues(alpha: 0.18 + (0.82 * amount))
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate((math.pi * 2 * i) / barCount - math.pi / 2);
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
  bool shouldRepaint(covariant _PullMarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
