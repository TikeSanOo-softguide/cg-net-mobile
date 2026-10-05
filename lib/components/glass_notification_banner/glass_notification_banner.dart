import 'dart:async';
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/in_app_notice.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Wraps the app and slides a frosted-glass banner in from the top whenever
/// [inAppNoticeProvider] receives a notice.
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
  static const _visibleFor = Duration(seconds: 4);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
    reverseDuration: const Duration(milliseconds: 260),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.4),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
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

    return Stack(
      children: [
        widget.child,
        if (notice != null)
          Positioned(
            top: topInset + 8,
            left: 12,
            right: 12,
            child: SlideTransition(
              position: _slide,
              child: FadeTransition(
                opacity: _controller,
                child: GestureDetector(
                  onTap: _handleTap,
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) < 0) _dismiss();
                  },
                  child: _GlassBanner(notice: notice),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlassBanner extends StatelessWidget {
  const _GlassBanner({required this.notice});

  final InAppNotice notice;

  static final _radius = BorderRadius.circular(22);

  @override
  Widget build(BuildContext context) {
    final body = notice.body;

    return Semantics(
      liveRegion: true,
      button: true,
      label: [notice.title, if (body != null) body].join('. '),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: _radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: _radius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.78),
                    AppColors.primaryLight.withValues(alpha: 0.62),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.7),
                  width: 0.8,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/branding/app_icon.png',
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'YNO',
                                  style: AppTheme.english(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                              Text(
                                DateFormat.Hm().format(notice.receivedAt),
                                style: AppTheme.english(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            notice.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          if (body != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.english(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
