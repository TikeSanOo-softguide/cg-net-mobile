import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors/app_colors.dart';

const _slideDuration = Duration(milliseconds: 200);
const _slideReverseDuration = Duration(milliseconds: 180);

/// Starts immediately and settles briefly. The same curve is used for pop
/// so the page does not hesitate before it leaves.
const _motionCurve = Cubic(0.2, 0.9, 0.25, 1.0);

/// Full-screen push. The page stays opaque so the route canvas does not flash.
CustomTransitionPage<T> slidePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: ColoredBox(
      color: AppColors.background,
      child: child,
    ),
    transitionDuration: _slideDuration,
    reverseTransitionDuration: _slideReverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return _SmoothSlide(
        animation: animation,
        secondaryAnimation: secondaryAnimation,
        child: child,
      );
    },
  );
}

/// Same slide for pages opened with [Navigator.push] instead of GoRouter.
class SlidePageRoute<T> extends PageRouteBuilder<T> {
  SlidePageRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) {
            return ColoredBox(
              color: AppColors.background,
              child: builder(context),
            );
          },
          transitionDuration: _slideDuration,
          reverseTransitionDuration: _slideReverseDuration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _SmoothSlide(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
        );
}

class _SmoothSlide extends StatefulWidget {
  const _SmoothSlide({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  State<_SmoothSlide> createState() => _SmoothSlideState();
}

class _SmoothSlideState extends State<_SmoothSlide> {
  late final CurvedAnimation _primary;
  late final CurvedAnimation _secondary;
  late final Animation<Offset> _incoming;
  late final Animation<Offset> _outgoing;

  @override
  void initState() {
    super.initState();
    _primary = CurvedAnimation(
      parent: widget.animation,
      curve: _motionCurve,
      reverseCurve: _motionCurve,
    );
    _secondary = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: _motionCurve,
      reverseCurve: _motionCurve,
    );
    _incoming = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(_primary);
    _outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.2, 0),
    ).animate(_secondary);
  }

  @override
  void dispose() {
    _primary.dispose();
    _secondary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _outgoing,
      child: SlideTransition(
        position: _incoming,
        child: AnimatedBuilder(
          animation: _primary,
          child: RepaintBoundary(child: widget.child),
          builder: (context, child) {
            final strength = 1 - _primary.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color.fromRGBO(0, 0, 0, 0.12 * strength),
                  ),
                ),
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
