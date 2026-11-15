import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../app_spinner/app_spinner.dart';

/// Pull-to-refresh that keeps the list in place and shows [AppSpinner].
class AppRefreshIndicator extends StatefulWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
    this.color = AppColors.primary,
  });

  final RefreshCallback onRefresh;
  final Widget child;
  final double edgeOffset;
  final Color color;

  @override
  State<AppRefreshIndicator> createState() => _AppRefreshIndicatorState();
}

class _AppRefreshIndicatorState extends State<AppRefreshIndicator> {
  RefreshIndicatorStatus? _status;

  bool get _visible {
    return _status == RefreshIndicatorStatus.drag ||
        _status == RefreshIndicatorStatus.armed ||
        _status == RefreshIndicatorStatus.snap ||
        _status == RefreshIndicatorStatus.refresh;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (status) {
            if (!mounted || status == _status) return;
            setState(() => _status = status);
          },
          child: widget.child,
        ),
        if (_visible)
          Positioned(
            top: widget.edgeOffset + 6,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AppSpinner(size: 28, color: widget.color),
              ),
            ),
          ),
      ],
    );
  }
}
