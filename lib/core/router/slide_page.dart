import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors/app_colors.dart';

const _slideDuration = Duration(milliseconds: 280);
const _slideReverseDuration = Duration(milliseconds: 240);

const _enterCurve = Cubic(0.22, 1.0, 0.36, 1.0);
const _exitCurve = Cubic(0.4, 0.0, 1.0, 1.0);

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
  late final Animation<double> _edgeShadow;

  @override
  void initState() {
    super.initState();
    _primary = CurvedAnimation(
      parent: widget.animation,
      curve: _enterCurve,
      reverseCurve: _exitCurve,
    );
    _secondary = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: _enterCurve,
      reverseCurve: _exitCurve,
    );
    _incoming = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(_primary);
    _outgoing = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.3, 0),
    ).animate(_secondary);
    _edgeShadow = Tween<double>(begin: 1, end: 0).animate(_primary);
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
          animation: _edgeShadow,
          child: RepaintBoundary(child: widget.child),
          builder: (context, child) {
            final strength = _edgeShadow.value;
            return DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.16 * strength),
                    blurRadius: 18,
                    offset: const Offset(-8, 0),
                  ),
                ],
              ),
              child: child,
            );
          },
        ),
      ),
    );
  }
}
