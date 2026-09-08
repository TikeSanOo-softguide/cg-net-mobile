import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import 'components/home_active_plan_card.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                HomeHeader(
                  accountNumber: data.accountNumber,
                  balanceAmount: data.balanceAmount,
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -40,
                  child: const HomeQuickActions(),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 56)),
          SliverToBoxAdapter(
            child: HomeActivePlanCard(
              planTitle: data.planTitle,
              planExpiry: data.planExpiry,
              username: data.username,
              password: data.password,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          const SliverToBoxAdapter(child: HomeServicesSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          const SliverToBoxAdapter(child: HomePromoBanner()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          const SliverToBoxAdapter(child: HomeOffersSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
