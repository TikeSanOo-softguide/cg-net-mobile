import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/promotion_ads_modal/promotion_ads_modal.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/ui/bottom_nav_visibility_provider.dart';
import '../../../data/launch_promo/launch_promo_repository.dart';
import '../../../data/promotion/promotion_repository.dart';
import '../../../data/profile/profile_repository.dart';
import '../../profile/profile/profile_controller.dart';
import 'components/home_cg_package_section.dart';
import 'components/home_header.dart';
import 'components/home_offers_section.dart';
import 'components/home_plan_card.dart';
import 'components/home_promo_alert.dart';
import 'components/home_promo_banner.dart';
import 'components/home_quick_actions.dart';
import 'components/home_section_header.dart';
import 'components/home_services_section.dart';
import 'components/home_special_offer_section.dart';

/// Special data packages stay in the project, but are not shown on Home.
const _showSpecialDataPackages = false;

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

  Future<void> _refreshSession() {
    ref.invalidate(homePromotionsProvider);
    return ref.read(profileControllerProvider.notifier).fetchProfile();
  }

  Future<void> _maybeShowLaunchPromotion() async {
    if (!mounted || _launchPromoShowing) return;
    final pending = ref.read(pendingLaunchPromotionProvider);
    if (!pending || _launchPromoHandled) return;

    _launchPromoHandled = true;
    _launchPromoShowing = true;
    ref.read(pendingLaunchPromotionProvider.notifier).state = false;

    try {
      if (!mounted) return;
      final advertisements = await ref.read(activeAdvertisementProvider.future);
      if (!mounted || advertisements.isEmpty) return;
      await showPromotionAdsModal(
        context,
        images: advertisements,
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

    final liveProfile = ref.watch(profileControllerProvider);
    final cachedProfile = ref.watch(cachedUserProfileProvider);
    final hasLiveProfile = liveProfile.fullName.isNotEmpty ||
        liveProfile.phone.isNotEmpty ||
        liveProfile.accountNumber.isNotEmpty;
    final displayProfile =
        hasLiveProfile ? liveProfile : cachedProfile.valueOrNull;
    final localeCode = ref.watch(appLocaleProvider);
    final showNav = ref.watch(bottomNavVisibleProvider);

    // Strip bottom inset only while shell bottom nav (with its SafeArea) is shown.
    final pinnedH = HomePinnedBar.heightOf(context);

    return MediaQuery.removePadding(
      context: context,
      removeBottom: showNav,
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              edgeOffset: pinnedH,
              onRefresh: _refreshSession,
              child: CustomScrollView(
                key: ValueKey('home-$localeCode'),
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: SizedBox(height: pinnedH - 2),
                  ),
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HomeBalanceHeader(
                              balanceAmount:
                                  displayProfile?.walletBalance.isNotEmpty ==
                                          true
                                      ? displayProfile!.walletBalance
                                      : cachedProfile.isLoading
                                          ? ''
                                          : '—',
                            ),
                            const SizedBox(height: HomeQuickActions.hangBelow),
                          ],
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: HomeQuickActions(),
                        ),
                      ],
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: HomeSectionHeader.sectionGap),
                  ),
                  SliverToBoxAdapter(
                    child: const HomePlanCard(),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: HomeSectionHeader.sectionGap),
                  ),
                  const SliverToBoxAdapter(child: HomeServicesSection()),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: HomeSectionHeader.sectionGap),
                  ),
                  const SliverToBoxAdapter(child: HomePromoAlert()),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: HomeSectionHeader.sectionGap),
                  ),
                  if (_showSpecialDataPackages) ...[
                    const SliverToBoxAdapter(child: HomeOffersSection()),
                    const SliverToBoxAdapter(
                      child: SizedBox(height: HomeSectionHeader.sectionGap),
                    ),
                  ],
                  const SliverToBoxAdapter(child: HomeCgPackageSection()),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: HomeSectionHeader.sectionGap),
                  ),
                  const SliverToBoxAdapter(child: HomePromoBanner()),
                  const SliverToBoxAdapter(child: HomeSpecialOfferSection()),
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: HomePinnedBar(
                accountNumber: displayProfile?.phone ??
                    (cachedProfile.isLoading ? '' : '—'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
