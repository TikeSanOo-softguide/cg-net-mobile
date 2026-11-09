import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/in_app_notice.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Foreground heads-up notice — KPay / iOS-style card under the status bar.
class GlassNotificationHost extends ConsumerStatefulWidget {
  const GlassNotificationHost({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  ConsumerState<GlassNotificationHost> createState() =>
      _GlassNotificationHostState();
}

class _GlassNotificationHostState extends ConsumerState<GlassNotificationHost>
    with SingleTickerProviderStateMixin {
  static const _visibleFor = Duration(seconds: 5);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.15),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  InAppNotice? _notice;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _present(InAppNotice notice) {
    HapticFeedback.lightImpact();
    setState(() => _notice = notice);
    _controller.forward(from: _controller.isDismissed ? 0 : _controller.value);
    _hideTimer?.cancel();
    _hideTimer = Timer(_visibleFor, _dismiss);
  }

  Future<void> _dismiss() async {
    _hideTimer?.cancel();
    await _controller.reverse();
    if (!mounted) return;
    setState(() => _notice = null);
    ref.read(inAppNoticeProvider.notifier).state = null;
  }

  void _handleTap() {
    _dismiss();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<InAppNotice?>(inAppNoticeProvider, (previous, next) {
      if (next != null && next.id != previous?.id) _present(next);
    });

    final notice = _notice;
    final topInset = MediaQuery.paddingOf(context).top;
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    return Stack(
      children: [
        widget.child,
        if (notice != null)
          Positioned(
            top: topInset + (isIos ? 6 : 8),
            left: 10,
            right: 10,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _controller,
                child: GestureDetector(
                  onTap: _handleTap,
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < 0) _dismiss();
                  },
                  child: _HeadsUpBanner(notice: notice, isIos: isIos),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeadsUpBanner extends StatelessWidget {
  const _HeadsUpBanner({
    required this.notice,
    required this.isIos,
  });

  final InAppNotice notice;
  final bool isIos;

  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    final body = notice.body?.trim();
    final hasBody = body != null && body.isNotEmpty;
    final content = _BannerContent(
      title: notice.title,
      body: hasBody ? body : null,
    );

    return Semantics(
      liveRegion: true,
      button: true,
      label: [notice.title, if (hasBody) body].join('. '),
      child: isIos ? _IosCard(child: content) : _AndroidCard(child: content),
    );
  }
}

class _IosCard extends StatelessWidget {
  const _IosCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_HeadsUpBanner._radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_HeadsUpBanner._radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: ColoredBox(
            color: Colors.white.withValues(alpha: 0.92),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AndroidCard extends StatelessWidget {
  const _AndroidCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(_HeadsUpBanner._radius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.title,
    this.body,
  });

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/branding/app_icon.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'app_name'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'common.now'.tr(),
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textMuted,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: AppTheme.lineHeightMyanmarSafe,
                    letterSpacing: 0,
                  ),
                ),
                if (body != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    body!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
