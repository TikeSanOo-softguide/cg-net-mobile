import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../data/launch_promo/launch_promo_repository.dart';

/// Legacy launch route — forwards into Home so the reusable ads modal can
/// appear as an overlay on top of the real screen.
class AdvertisementPage extends ConsumerStatefulWidget {
  const AdvertisementPage({super.key});

  @override
  ConsumerState<AdvertisementPage> createState() => _AdvertisementPageState();
}

class _AdvertisementPageState extends ConsumerState<AdvertisementPage> {
  bool _forwarded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _forwarded) return;
      _forwarded = true;
      ref.read(pendingLaunchPromotionProvider.notifier).state = true;
      context.goNamed(RouteNames.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.onPrimary),
      ),
    );
  }
}
