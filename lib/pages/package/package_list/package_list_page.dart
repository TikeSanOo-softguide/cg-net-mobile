import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../models/package_model/package_model.dart';
import '../components/luxury_package_card.dart';
import 'package_list_controller.dart';

/// Packages tab — compact CG-NET product cards.
class PackageListPage extends ConsumerWidget {
  const PackageListPage({super.key});

  void _openDetail(BuildContext context, String id) {
    context.pushNamed(
      RouteNames.packageDetail,
      pathParameters: {'id': id},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final state = ref.watch(packageListControllerProvider);

    return AppCurvedScaffold(
      title: Text('package.title'.tr()),
      showBack: false,
      body: switch (state.status) {
        PackageListStatus.loading => const ShimmerLoading(
            itemCount: 6,
            itemHeight: 128,
          ),
        PackageListStatus.empty => EmptyState(
            iconAsset: QuickActionIconChip.packageAsset,
            iconBackground: QuickActionIconChip.packageSoft,
            title: 'package.empty_title'.tr(),
            message: 'package.empty_body'.tr(),
            actionLabel: 'common.retry'.tr(),
            onAction: () =>
                ref.read(packageListControllerProvider.notifier).load(),
          ),
        PackageListStatus.error => EmptyState(
            icon: LucideIcons.wifi_off,
            iconAsset: state.errorMessage == 'api.offline'
                ? null
                : QuickActionIconChip.packageAsset,
            iconBackground: QuickActionIconChip.packageSoft,
            title: 'common.error'.tr(),
            message: apiMessageText(state.errorMessage),
            actionLabel: 'common.retry'.tr(),
            onAction: () async {
              const recoveryKey = 'package-list-load';
              if (state.errorMessage == 'api.offline') {
                ref.read(networkRecoveryControllerProvider).enqueue(
                      recoveryKey,
                      () async => ref
                          .read(packageListControllerProvider.notifier)
                          .load(),
                    );
                final shouldRetry = await openNoInternetPage(context);
                if (shouldRetry == true && context.mounted) {
                  ref
                      .read(networkRecoveryControllerProvider)
                      .clear(recoveryKey);
                  ref.read(packageListControllerProvider.notifier).load();
                }
                return;
              }
              ref.read(packageListControllerProvider.notifier).load();
            },
          ),
        PackageListStatus.data => ListView.separated(
            key: ValueKey('package-list-$locale'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: state.packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = _PackageListData.fromModel(
                state.packages[index],
                localeCode: locale,
              );
              return LuxuryPackageCard(
                title: data.title,
                priceLabel: '${data.price} ${'topup.pts'.tr()}',
                periodLabel: data.cycle.isEmpty
                    ? 'home.offer_month'.tr()
                    : '/ ${data.cycle}',
                speedLabel: data.speed.contains('Mbps')
                    ? data.speed
                    : '${data.speed} Mbps',
                popular: data.popular,
                onTap: () => _openDetail(context, data.id),
                onBuy: () => _openDetail(context, data.id),
              );
            },
          ),
      },
    );
  }
}

class _PackageListData {
  const _PackageListData({
    required this.id,
    required this.title,
    required this.speed,
    required this.cycle,
    required this.price,
    required this.popular,
  });

  final String id;
  final String title;
  final String speed;
  final String cycle;
  final String price;
  final bool popular;

  factory _PackageListData.fromModel(
    PackageModel model, {
    required String localeCode,
  }) {
    final title = model.localizedName?[localeCode] ??
        model.localizedName?['en'] ??
        model.name;
    final cycle = model.termMonths == null
        ? model.billingCycle
        : '${model.termMonths} ${model.billingCycle}'.trim();
    final price = model.price == model.price.roundToDouble()
        ? model.price.toInt().toString()
        : model.price.toString();

    return _PackageListData(
      id: model.id,
      title: title,
      speed: model.speed.trim(),
      cycle: cycle,
      price: price,
      popular: model.recommended,
    );
  }
}

