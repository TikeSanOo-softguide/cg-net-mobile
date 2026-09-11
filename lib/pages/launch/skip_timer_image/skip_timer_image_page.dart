import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/timed_skip_image_scaffold/timed_skip_image_scaffold.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../data/launch_promo/launch_promo_repository.dart';

/// Authenticated launch step: promotional image with skip countdown.
class SkipTimerImagePage extends ConsumerStatefulWidget {
  const SkipTimerImagePage({super.key});

  @override
  ConsumerState<SkipTimerImagePage> createState() => _SkipTimerImagePageState();
}

class _SkipTimerImagePageState extends ConsumerState<SkipTimerImagePage> {
  bool _navigated = false;
  bool _errorScheduled = false;

  void _goHomeForPromotion() {
    if (!mounted || _navigated) return;
    _navigated = true;
    // Home hosts the premium ads modal overlay.
    ref.read(pendingLaunchPromotionProvider.notifier).state = true;
    context.goNamed(RouteNames.home);
  }

  void _scheduleContinue() {
    if (_navigated || _errorScheduled) return;
    _errorScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _goHomeForPromotion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncPromo = ref.watch(skipTimerPromoProvider);

    return asyncPromo.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.onPrimary),
        ),
      ),
      error: (_, __) {
        _scheduleContinue();
        return const Scaffold(backgroundColor: AppColors.primary);
      },
      data: (promo) {
        return TimedSkipImageScaffold(
          imagePath: promo.image,
          durationSeconds: promo.durationSeconds,
          backgroundColor: AppColors.primary,
          fit: BoxFit.cover,
          onContinue: _goHomeForPromotion,
        );
      },
    );
  }
}
