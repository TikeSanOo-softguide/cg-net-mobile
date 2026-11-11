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
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/message_codes.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../core/utils/date_time_format.dart';
import '../../../data/history/history_repository.dart';
import '../../../models/history_model/history_model.dart';
import '../pay_bill/pay_bill_result.dart';

final serviceHistoryProvider =
    FutureProvider.autoDispose<List<HistoryModel>>((ref) {
  return ref.watch(historyRepositoryProvider).fetchService();
});

class ServiceHistoryPage extends ConsumerWidget {
  const ServiceHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final history = ref.watch(serviceHistoryProvider);

    return AppCurvedScaffold(
      key: ValueKey('service-history-$locale'),
      title: Text('home.service_history'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: history.when(
        data: (items) {
          if (items.isEmpty) return const _ServiceHistoryEmpty();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 5),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ServiceHistoryRow(
                item: item,
                onTap: () => _openDetail(context, ref, item),
              );
            },
          );
        },
        loading: () => const ShimmerLoading(itemCount: 5, itemHeight: 88),
        error: (error, _) => EmptyState(
          icon: LucideIcons.wifi_off,
          iconAsset: isOfflineError(error) ? null : QuickActionIconChip.billAsset,
          iconBackground: QuickActionIconChip.billSoft,
          title: isOfflineError(error)
              ? 'shared.no_internet_title'.tr()
              : 'common.error'.tr(),
          message: isOfflineError(error)
              ? 'shared.no_internet_body'.tr()
              : apiErrorText(error),
          actionLabel: 'common.retry'.tr(),
          onAction: () async {
            const recoveryKey = 'service-history-reload';
            if (isOfflineError(error)) {
              ref.read(networkRecoveryControllerProvider).enqueue(
                    recoveryKey,
                    () async => ref.invalidate(serviceHistoryProvider),
                  );
              final shouldRetry = await openNoInternetPage(context);
              if (shouldRetry == true && context.mounted) {
                ref.read(networkRecoveryControllerProvider).clear(recoveryKey);
                ref.invalidate(serviceHistoryProvider);
              }
              return;
            }
            ref.invalidate(serviceHistoryProvider);
          },
        ),
      ),
    );
  }

  Future<void> _openDetail(
    BuildContext context,
    WidgetRef ref,
    HistoryModel item,
  ) async {
    var detail = item;
    try {
      if (item.id.isNotEmpty) {
        detail = await ref
            .read(historyRepositoryProvider)
            .fetchServiceById(item.id);
      }
    } catch (_) {}
    if (!context.mounted) return;

    final pending = PayBillResult.isPendingStatus(detail.status);
    final amount = detail.amount?.round() ?? 0;
    final result = pending
        ? PayBillResult.pending(
            amountPoints: amount,
            account: detail.account,
            serviceType: detail.serviceType,
            productLabel: detail.productName,
            speed: detail.productSpeed,
            transactionId: detail.transactionNo ?? '',
            occurredAt: detail.createdAt,
            remark: detail.remark,
          )
        : PayBillResult.success(
            amountPoints: amount,
            account: detail.account,
            serviceType: detail.serviceType,
            productLabel: detail.productName,
            speed: detail.productSpeed,
            transactionId: detail.transactionNo ?? '',
            occurredAt: detail.createdAt,
            remark: detail.remark,
          );

    await context.pushNamed(
      pending ? RouteNames.payBillPending : RouteNames.payBillSuccess,
      extra: result,
      queryParameters: pending ? const {} : const {'hideDone': '1'},
    );
  }
}

class _ServiceHistoryEmpty extends StatelessWidget {
  const _ServiceHistoryEmpty();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppStyle.spaceLg),
      children: [
        AppCard(
          elevated: false,
          bordered: false,
          padding: const EdgeInsets.all(AppStyle.spaceXxl),
          child: Column(
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(
                  Color(0xFF7C3AED),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  'assets/images/services/history.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(height: AppStyle.spaceMd),
              Text(
                'history.empty_title'.tr(),
                style: AppTheme.sectionTitle(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyle.spaceXs),
              Text(
                'history.empty_body'.tr(),
                textAlign: TextAlign.center,
                style: AppTheme.bodySecondary(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ServiceHistoryRow extends StatelessWidget {
  const _ServiceHistoryRow({
    required this.item,
    required this.onTap,
  });

  final HistoryModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final title = item.titleCode.isNotEmpty
        ? MessageCodes.locKey(item.titleCode).tr()
        : 'history.item_bill_title'.tr();
    final body = item.descriptionCode.isNotEmpty
        ? MessageCodes.locKeyBody(item.descriptionCode).tr()
        : 'history.item_bill_body'.tr();
    final amount = item.amount == null
        ? '-'
        : '-${NumberFormat('#,##0.##', locale.toString()).format(item.amount)} ${'topup.pts'.tr()}';
    final date = formatDate(item.createdAt.toIso8601String());

    return AppCard(
      onTap: onTap,
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickActionIconChip(
            asset: QuickActionIconChip.billAsset,
            background: QuickActionIconChip.billSoft,
            size: 38,
            iconSize: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                          height: locale.languageCode == 'my'
                              ? AppTheme.lineHeightMyanmarSafe
                              : 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
