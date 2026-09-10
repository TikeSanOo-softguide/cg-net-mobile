import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/app_locale_provider.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import 'components/home_header.dart';
import 'components/home_offers_section.dart';
import 'components/home_promo_banner.dart';
import 'components/home_quick_actions.dart';
import 'components/home_services_section.dart';
import 'home_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(homeControllerProvider);
    // Rebuild home content immediately when language changes.
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
          const SliverToBoxAdapter(child: HomeServicesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: AppStyle.spaceXl)),
          const SliverToBoxAdapter(child: HomePromoBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: AppStyle.spaceXl)),
          const SliverToBoxAdapter(child: HomeOffersSection()),
          const SliverToBoxAdapter(child: SizedBox(height: AppStyle.spaceXxl)),
        ],
      ),
    );
  }
}
