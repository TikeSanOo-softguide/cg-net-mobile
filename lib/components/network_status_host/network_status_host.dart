import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/network_monitor.dart';
import '../../core/network/network_status.dart';
import '../../core/router/route_names/route_names.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../app_dialog/app_dialog.dart';

enum NetworkNotice { none, offline, backOnline }

/// Asks the global offline sentence to show again, including during a pull
/// while the phone is already offline.
class GlobalOfflineNotice {
  GlobalOfflineNotice._();

  static final List<VoidCallback> _listeners = [];

  static void show() {
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
  }

  static void register(VoidCallback listener) => _listeners.add(listener);

  static void unregister(VoidCallback listener) => _listeners.remove(listener);
}

/// Decides when the global notice is allowed to appear.
class NetworkNoticePolicy {
  bool _offlineVisible = false;

  NetworkNotice onStatus(NetworkStatus status) {
    if (status == NetworkStatus.checking) return NetworkNotice.none;
    if (status == NetworkStatus.offline) {
      if (_offlineVisible) return NetworkNotice.none;
      _offlineVisible = true;
      return NetworkNotice.offline;
    }
    if (_offlineVisible) {
      _offlineVisible = false;
      return NetworkNotice.backOnline;
    }
    return NetworkNotice.none;
  }
}

/// One centered sentence when the internet drops, and one when it returns.
///
/// Splash, onboarding, and the launch promo stay clear. The first notice
/// waits until login (signed out) or home (signed in). After that, every
/// page can show it.
class NetworkStatusHost extends ConsumerStatefulWidget {
  const NetworkStatusHost({super.key, required this.child, this.router});

  final Widget child;
  final GoRouter? router;

  @override
  ConsumerState<NetworkStatusHost> createState() => _NetworkStatusHostState();
}

class _NetworkStatusHostState extends ConsumerState<NetworkStatusHost> {
  final _policy = NetworkNoticePolicy();
  Timer? _timer;
  NetworkNotice _notice = NetworkNotice.none;
  bool _ready = false;
  late final VoidCallback _onOfflineRequest;

  @override
  void initState() {
    super.initState();
    _onOfflineRequest = () {
      if (!_ready || !mounted) return;
      _show(NetworkNotice.offline);
    };
    GlobalOfflineNotice.register(_onOfflineRequest);
    final router = widget.router;
    if (router == null) {
      _ready = true;
      return;
    }
    router.routeInformationProvider.addListener(_onRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _armIfReady());
  }

  @override
  void dispose() {
    GlobalOfflineNotice.unregister(_onOfflineRequest);
    widget.router?.routeInformationProvider.removeListener(_onRoute);
    _timer?.cancel();
    super.dispose();
  }

  bool _isRevealPath(String path) {
    return path == RoutePaths.login || path == RoutePaths.home;
  }

  void _onRoute() => _armIfReady();

  void _armIfReady() {
    if (_ready || !mounted) return;
    final router = widget.router;
    if (router == null) return;
    if (!_isRevealPath(router.routeInformationProvider.value.uri.path)) {
      return;
    }
    _ready = true;
    final notice = _policy.onStatus(ref.read(networkMonitorProvider));
    if (notice == NetworkNotice.none) return;
    _show(notice);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NetworkStatus>(networkMonitorProvider, (previous, next) {
      if (!_ready) return;
      final notice = _policy.onStatus(next);
      if (notice == NetworkNotice.none || !mounted) return;
      _show(notice);
    });
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_notice != NetworkNotice.none)
          Positioned(
            left: 16,
            right: 16,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.center,
                child: _GlobalNoticeBar(
                  offline: _notice == NetworkNotice.offline,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _show(NetworkNotice notice) {
    if (notice == NetworkNotice.backOnline) {
      OfflineModalHub.dismiss();
    }
    _timer?.cancel();
    setState(() => _notice = notice);
    _timer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _notice = NetworkNotice.none);
    });
  }
}

class _GlobalNoticeBar extends StatelessWidget {
  const _GlobalNoticeBar({required this.offline});

  final bool offline;

  static const _wifiAsset = 'assets/images/dialogs/wifi-connection.png';
  static const _checkAsset = 'assets/images/dialogs/check-mark.png';

  @override
  Widget build(BuildContext context) {
    if (offline) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x8C000000),
          borderRadius: AppStyle.borderRadiusSm,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: 0.6,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Text(
            'shared.offline_notice'.tr(),
            textAlign: TextAlign.start,
            textWidthBasis: TextWidthBasis.longestLine,
            style: _labelStyle(Colors.white),
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.success,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x471B7A4E),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 7, 8, 7),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final textMax = (constraints.maxWidth - 64).clamp(
              80.0,
              constraints.maxWidth,
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _NoticeIcon(_wifiAsset),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: textMax),
                  child: Text(
                    'shared.back_online_notice'.tr(),
                    textAlign: TextAlign.start,
                    style: _labelStyle(Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                const _NoticeIcon(_checkAsset, button: true),
              ],
            );
          },
        ),
      ),
    );
  }

  TextStyle _labelStyle(Color color, {double fontSize = 15}) {
    return AppTheme.english(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
      height: AppStyle.lineHeightBody,
    ).copyWith(decoration: TextDecoration.none);
  }
}

class _NoticeIcon extends StatelessWidget {
  const _NoticeIcon(this.asset, {this.button = false});

  final String asset;
  final bool button;

  @override
  Widget build(BuildContext context) {
    final size = button ? 16.0 : 14.0;
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
