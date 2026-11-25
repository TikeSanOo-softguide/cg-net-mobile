import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../components/app_refresh_indicator/app_refresh_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/offline_notice_bar/offline_notice_bar.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../components/page_skeletons/package_skeletons.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
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

    final hasPackages = state.packages.isNotEmpty;
    final unreachable = isUnreachableMessage(state.errorMessage);
    final serverDown = isServerUnavailableMessage(state.errorMessage);
    final Widget body;
    if (hasPackages || state.status == PackageListStatus.loading) {
      body = _refreshable(
        ref,
        CustomScrollView(
          key: ValueKey('package-list-$locale'),
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: hasPackages
                  ? const _PackagePageIntro()
                  : const PackageTitleSkeleton(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                10,
                10,
                10,
                AppStyle.listPaddingBottom,
              ),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 232,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => hasPackages
                      ? _packageCard(context, state, index)
                      : const PackageCardSkeleton(),
                  childCount: hasPackages ? state.packages.length : 4,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (state.status == PackageListStatus.error) {
      body = _refreshable(
        ref,
        _scrollableFill(
          unreachable
              ? OfflineEmptyState(
                  scrollable: false,
                  onRetry: () => _retry(ref, state),
                )
              : serverDown
                  ? ServerUnavailableEmptyState(
                      scrollable: false,
                      recoveryKey: 'package-list',
                      onRetry: () => _retry(ref, state),
                    )
              : EmptyState(
                  iconAsset: QuickActionIconChip.packageAsset,
                  iconBackground: QuickActionIconChip.packageSoft,
                  title: 'common.error'.tr(),
                  message: apiMessageText(state.errorMessage),
                  actionLabel: 'common.retry'.tr(),
                  onAction: () => _retry(ref, state),
                ),
        ),
      );
    } else {
      body = _refreshable(
        ref,
        _scrollableFill(
          EmptyState(
            iconAsset: QuickActionIconChip.packageAsset,
            iconBackground: QuickActionIconChip.packageSoft,
            title: 'package.empty_title'.tr(),
            message: 'package.empty_body'.tr(),
            actionLabel: 'common.retry'.tr(),
            onAction: () =>
                ref.read(packageListControllerProvider.notifier).load(),
          ),
        ),
      );
    }

    return AppCurvedScaffold(
      title: Text('package.title'.tr()),
      showBack: false,
      body: body,
    );
  }

  Widget _refreshable(WidgetRef ref, Widget child) {
    return AppRefreshIndicator(
      color: AppColors.primary,
      recoveryKey: 'package-list',
      onRefresh: () async {
        await ref.read(packageListControllerProvider.notifier).load(
              silent: true,
            );
      },
      child: child,
    );
  }

  Widget _scrollableFill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: constraints.maxHeight, child: child),
          ],
        );
      },
    );
  }

  void _retry(WidgetRef ref, PackageListState state) {
    final notifier = ref.read(packageListControllerProvider.notifier);
    if (isUnreachableMessage(state.errorMessage)) {
      armOfflineRetry(
        recovery: ref.read(networkRecoveryControllerProvider),
        key: 'package-list-load',
        reload: () => notifier.load(rethrowOffline: true),
      );
      return;
    }
    notifier.load();
  }

  Widget _packageCard(
    BuildContext context,
    PackageListState state,
    int index,
  ) {
    final data = _PackageListData.fromModel(state.packages[index]);
    return LuxuryPackageCard(
      title: data.line.isNotEmpty ? data.line : state.packages[index].name,
      productId: data.id,
      lineLabel: data.line,
      priceLabel: data.price,
      periodLabel: data.cycle,
      speedLabel: data.speed,
      popular: data.popular,
      accentIndex: index,
      compact: true,
      onTap: () => _openDetail(context, data.id),
      onBuy: () => _openDetail(context, data.id),
    );
  }
}

class _PackagePageIntro extends StatelessWidget {
  const _PackagePageIntro();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'package.popular_plan'.tr(),
                      style: AppTheme.english(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Row(
                children: [
                  _PlanDot(index: 0),
                  SizedBox(width: 6),
                  _PlanDot(index: 1),
                  SizedBox(width: 6),
                  _PlanDot(index: 2),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanDot extends StatelessWidget {
  const _PlanDot({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LuxuryPackageCard.accentAt(index),
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 10, height: 10),
    );
  }
}

class _PackageListData {
  const _PackageListData({
    required this.id,
    required this.speed,
    required this.cycle,
    required this.price,
    required this.popular,
    required this.line,
  });

  final String id;
  final String speed;
  final String cycle;
  final String price;
  final bool popular;
  final String line;

  factory _PackageListData.fromModel(PackageModel model) {
    final speed = model.speed.trim();
    final cycle = [
      if (model.termMonths != null) '${model.termMonths}',
      model.billingCycle.trim(),
    ].join();
    final price = '${model.price}';

    return _PackageListData(
      id: model.id,
      speed: speed.toLowerCase().contains('mbps') ? speed : '$speed Mbps',
      cycle: cycle,
      price: price,
      popular: model.recommended,
      line: model.currency.trim(),
    );
  }
}
