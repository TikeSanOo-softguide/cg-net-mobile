import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Full-screen image + countdown Skip control with safe single-fire navigation.
class TimedSkipImageScaffold extends StatefulWidget {
  const TimedSkipImageScaffold({
    super.key,
    required this.imagePath,
    required this.durationSeconds,
    required this.onContinue,
    this.fit = BoxFit.cover,
    this.backgroundColor = AppColors.primary,
    this.isNetworkImage = false,
  });

  final String imagePath;
  final int durationSeconds;
  final VoidCallback onContinue;
  final BoxFit fit;
  final Color backgroundColor;
  final bool isNetworkImage;

  @override
  State<TimedSkipImageScaffold> createState() => _TimedSkipImageScaffoldState();
}

class _TimedSkipImageScaffoldState extends State<TimedSkipImageScaffold>
    with WidgetsBindingObserver {
  Timer? _timer;
  late int _remaining;
  bool _completed = false;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remaining = widget.durationSeconds.clamp(1, 60);
    _startTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_completed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _paused = true;
      _timer?.cancel();
      _timer = null;
      return;
    }
    if (state == AppLifecycleState.resumed && _paused) {
      _paused = false;
      if (_remaining <= 0) {
        _finish();
      } else {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _completed) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        _remaining = 0;
        if (mounted) setState(() {});
        _finish();
        return;
      }
      if (mounted) setState(() => _remaining -= 1);
    });
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    _timer?.cancel();
    _timer = null;
    if (!mounted) return;
    widget.onContinue();
  }

  void _onSkip() => _finish();

  Widget _buildImage() {
    if (widget.isNetworkImage || widget.imagePath.startsWith('http')) {
      return Image.network(
        widget.imagePath,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return Image.asset(
      widget.imagePath,
      fit: widget.fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: widget.backgroundColor,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: widget.backgroundColor),
              _buildImage(),
              Positioned(
                top: top + AppStyle.spaceMd,
                right: AppStyle.spaceLg,
                child: _SkipChip(
                  remaining: _remaining,
                  onSkip: _onSkip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkipChip extends StatelessWidget {
  const _SkipChip({
    required this.remaining,
    required this.onSkip,
  });

  final int remaining;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSkip,
        borderRadius: BorderRadius.circular(20),
        overlayColor: WidgetStateProperty.all(
          Colors.white.withValues(alpha: 0.08),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'common.skip'.tr(),
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 22),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$remaining',
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
