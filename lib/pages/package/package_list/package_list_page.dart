import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/empty_state/empty_state.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import 'components/package_card.dart';
import 'package_list_controller.dart';

class PackageListPage extends ConsumerWidget {
  const PackageListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packageListControllerProvider);
    final controller = ref.read(packageListControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text('package.title'.tr())),
      body: switch (state.status) {
        PackageListStatus.loading => const ShimmerLoading(itemCount: 4),
        PackageListStatus.empty => EmptyState(
            title: 'package.empty_title'.tr(),
            message: 'package.empty_body'.tr(),
            icon: Icons.inventory_2_outlined,
            actionLabel: 'common.retry'.tr(),
            onAction: controller.load,
          ),
        PackageListStatus.error => EmptyState(
            title: 'common.error'.tr(),
            message: state.errorMessage ?? 'common.error'.tr(),
            icon: Icons.error_outline,
            actionLabel: 'common.retry'.tr(),
            onAction: controller.load,
          ),
        PackageListStatus.data => RefreshIndicator(
            onRefresh: controller.load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: state.packages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return PackageCard(package: state.packages[index]);
              },
            ),
          ),
      },
    );
  }
}
