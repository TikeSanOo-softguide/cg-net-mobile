import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/promotion_ads_modal/promotion_ads_modal.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../data/launch_promo/launch_promo_repository.dart';
import 'components/home_header.dart';
import 'components/home_offers_section.dart';
import 'components/home_plan_card.dart';
import 'components/home_promo_banner.dart';
import 'components/home_quick_actions.dart';
import 'components/home_services_section.dart';
import 'home_controller.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _launchPromoHandled = false;
  bool _launchPromoShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowLaunchPromotion();
    });
  }

  Future<void> _maybeShowLaunchPromotion() async {
    if (!mounted || _launchPromoShowing) return;
    final pending = ref.read(pendingLaunchPromotionProvider);
    if (!pending || _launchPromoHandled) return;

    _launchPromoHandled = true;
    _launchPromoShowing = true;
    ref.read(pendingLaunchPromotionProvider.notifier).state = false;

    try {
      final ad = await ref.read(activeAdvertisementProvider.future);
      if (!mounted) return;
      if (ad == null || !ad.isCurrentlyValid) return;
      await showPromotionAdsModal(
        context,
        imagePath: ad.image,
      );
    } catch (_) {
      // Empty / failed ads → stay on Home with no modal.
    } finally {
      _launchPromoShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(pendingLaunchPromotionProvider, (previous, next) {
      if (next != true) return;
      _launchPromoHandled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeShowLaunchPromotion();
      });
    });

    final data = ref.watch(homeControllerProvider);
    final localeCode = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        key: ValueKey('home-$localeCode'),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                HomeHeader(
                  accountNumber: data.accountNumber,
                  balanceAmount: data.balanceAmount,
                ),
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: -18,
                  child: HomeQuickActions(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 36)),
          SliverToBoxAdapter(
            child: HomePlanCard(
              title: data.planTitle,
              expiry: data.planExpiry,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppStyle.spaceXl)),
          const SliverToBoxAdapter(child: HomeServicesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: AppStyle.spaceXl)),
          const SliverToBoxAdapter(child: HomeOffersSection()),
          const SliverToBoxAdapter(child: SizedBox(height: AppStyle.spaceXl)),
          const SliverToBoxAdapter(child: HomePromoBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: AppStyle.spaceXxl)),
        ],
      ),
    );
  }
}
