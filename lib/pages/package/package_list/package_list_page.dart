import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/package_model/package_model.dart';
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
            itemHeight: 108,
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
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            itemCount: (state.packages.length + 1) ~/ 2,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, row) {
              final left = row * 2;
              final right = left + 1;
              _PackageListCard cardAt(int index) {
                final data = _PackageListData.fromModel(
                  state.packages[index],
                  localeCode: locale,
                );
                return _PackageListCard(
                  data: data,
                  onOpenDetail: () => _openDetail(context, data.id),
                );
              }

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: cardAt(left)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: right < state.packages.length
                          ? cardAt(right)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
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
    required this.line,
    required this.speed,
    required this.cycle,
    required this.price,
  });

  final String id;
  final String title;
  final String line;
  final String speed;
  final String cycle;
  final String price;

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
      line: model.currency.trim(),
      speed: model.speed.trim(),
      cycle: cycle,
      price: price,
    );
  }
}

class _PackageListCard extends StatelessWidget {
  const _PackageListCard({
    required this.data,
    required this.onOpenDetail,
  });

  final _PackageListData data;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      elevated: false,
      bordered: false,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      onTap: onOpenDetail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (data.line.isNotEmpty)
            Text(
              data.line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.english(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                height: AppTheme.lineHeightMyanmarSafe,
                letterSpacing: 0.6,
              ),
            ),
          if (data.line.isNotEmpty) const SizedBox(height: 4),
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: AppTheme.lineHeightMyanmarSafe,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LabeledValue(
                  label: 'package.speed'.tr(),
                  value: data.speed.isEmpty ? '—' : data.speed,
                ),
              ),
              Expanded(
                child: _LabeledValue(
                  label: 'broadband.duration'.tr(),
                  value: data.cycle.isEmpty ? '—' : data.cycle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                data.price,
                style: AppTheme.english(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'topup.pts'.tr(),
                style: AppTheme.english(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  height: 1,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.english(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.english(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}
