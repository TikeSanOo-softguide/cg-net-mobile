import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_filter_drawer/activity_filter_drawer.dart';
import '../../../components/app_refresh_indicator/app_refresh_indicator.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_glass_tab_bar/app_glass_tab_bar.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/offline_notice_bar/offline_notice_bar.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../components/page_skeletons/activity_skeletons.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
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
import '../../package/package_detail/package_buy_result.dart';
import '../pay_bill/pay_bill_result.dart';
import '../top_up/top_up_result.dart';

final quickActionHistoryProvider =
    FutureProvider.autoDispose.family<List<HistoryModel>, String?>(
  (ref, type) => ref.watch(historyRepositoryProvider).fetch(type: type),
);

/// History — tabs: All / Top-Up / Package / Bill.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late ActivityDateFilter _filter;

  static const _tabLabels = [
    'history.tab_all',
    'history.tab_topup',
    'history.tab_package',
    'history.tab_bill',
  ];
  static const _tabTypes = [
    null,
    'topup',
    'wifi_package',
    'ftth_bill',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _filter = ActivityDateFilter.defaults();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openFilter() async {
    final result = await showActivityFilterDrawer(
      context,
      initial: _filter,
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);

    return AppCurvedScaffold(
      key: ValueKey('history-$locale'),
      title: Text('history.title'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      trailingIcon: LucideIcons.sliders_horizontal,
      onTrailingPressed: _openFilter,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: AppGlassTabBar(
              controller: _tabController,
              labels: _tabLabels,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (var t = 0; t < 4; t++)
                  _HistoryList(
                    key: ValueKey(
                      'history-list-$locale-$t-${_filter.period}-${_filter.start}-${_filter.end}',
                    ),
                    type: _tabTypes[t],
                    filter: _filter,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({
    super.key,
    required this.type,
    required this.filter,
  });

  final String? type;
  final ActivityDateFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(quickActionHistoryProvider(type));

    final cached = history.valueOrNull;

    return AppRefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(quickActionHistoryProvider(type));
        try {
          await ref.read(quickActionHistoryProvider(type).future);
        } catch (_) {}
      },
      child: cached != null
          ? _historyItems(context, ref, cached)
          : history.isLoading
              ? const HistoryListSkeleton()
              : _pullableFill(
                  isUnreachableError(history.error)
                      ? OfflineEmptyState(
                          scrollable: false,
                          onRetry: () {
                            armOfflineRetry(
                              recovery: ref
                                  .read(networkRecoveryControllerProvider),
                              key: 'history-${type ?? 'all'}-reload',
                              reload: () async {
                                ref.invalidate(
                                  quickActionHistoryProvider(type),
                                );
                                try {
                                  await ref.read(
                                    quickActionHistoryProvider(type).future,
                                  );
                                } catch (error) {
                                  if (isOfflineError(error)) {
                                    throw const ApiException(
                                      ApiFailure.offline,
                                    );
                                  }
                                }
                              },
                            );
                          },
                        )
                      : isServerUnavailableError(history.error)
                          ? ServerUnavailableEmptyState(
                              scrollable: false,
                              onRetry: () {
                                ref.invalidate(quickActionHistoryProvider(type));
                              },
                            )
                      : EmptyState(
                          iconAsset: QuickActionIconChip.historyAsset,
                          iconBackground: QuickActionIconChip.historySoft,
                          title: 'common.error'.tr(),
                          message: apiErrorText(
                            history.error ?? 'common.error',
                          ),
                          actionLabel: 'common.retry'.tr(),
                          onAction: () {
                            ref.invalidate(quickActionHistoryProvider(type));
                          },
                        ),
                ),
    );
  }

  Widget _historyItems(
    BuildContext context,
    WidgetRef ref,
    List<HistoryModel> items,
  ) {
    final filteredItems = items
        .where((item) => filter.matches(item.createdAt.toLocal()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (filteredItems.isEmpty) return _pullableFill(_emptyState());

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: filteredItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        return _HistoryRow(
          item: item,
          onTap: _canOpen(item) ? () => _openDetail(context, ref, item) : null,
        );
      },
    );
  }

  Widget _pullableFill(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(height: constraints.maxHeight, child: child),
        );
      },
    );
  }

  Widget _emptyState() {
    final (asset, background) = switch (type) {
      'topup' => (
          QuickActionIconChip.topUpAsset,
          QuickActionIconChip.topUpSoft,
        ),
      'wifi_package' => (
          QuickActionIconChip.packageAsset,
          QuickActionIconChip.packageSoft,
        ),
      'ftth_bill' => (
          QuickActionIconChip.billAsset,
          QuickActionIconChip.billSoft,
        ),
      _ => (
          QuickActionIconChip.historyAsset,
          QuickActionIconChip.historySoft,
        ),
    };
    return EmptyState(
      iconAsset: asset,
      iconBackground: background,
      title: 'history.empty_title'.tr(),
      message: 'history.empty_body'.tr(),
    );
  }
}

bool _canOpen(HistoryModel item) {
  final type = item.type.toLowerCase();
  final status = item.status.toLowerCase();
  final pending = PayBillResult.isPendingStatus(status);
  return switch (type) {
    'topup' => status == 'completed' || status == 'failed' || pending,
    'wifi_package' => status == 'completed' || status == 'failed',
    'ftth_bill' || 'cg_bill' => status == 'completed' || pending,
    _ => false,
  };
}

String _packageDuration(String cycle, String unit) {
  return [cycle.trim(), unit.trim()].where((part) => part.isNotEmpty).join();
}

Future<void> _openDetail(
  BuildContext context,
  WidgetRef ref,
  HistoryModel item,
) async {
  final HistoryModel detail;
  try {
    detail = await ref.read(historyRepositoryProvider).fetchById(item.id);
  } catch (_) {
    return;
  }
  if (!context.mounted) return;

  final type = detail.type.toLowerCase();
  final status = detail.status.toLowerCase();
  final pending = PayBillResult.isPendingStatus(status);
  final amount = detail.amount?.round() ?? 0;
  final transactionId = detail.transactionNo ?? '';

  if (type == 'topup') {
    final serial = detail.serialMasked;
    final result = status == 'failed'
        ? TopUpResult.failure(
            amountPoints: amount,
            serialRaw: serial,
            transactionId: transactionId,
            occurredAt: detail.createdAt,
          )
        : pending
            ? TopUpResult.pending(
                amountPoints: amount,
                serialRaw: serial,
                transactionId: transactionId,
                occurredAt: detail.createdAt,
              )
            : TopUpResult.success(
                amountPoints: amount,
                serialRaw: serial,
                transactionId: transactionId,
                occurredAt: detail.createdAt,
              );
    final route = status == 'failed'
        ? RouteNames.topUpFailure
        : pending
            ? RouteNames.topUpPending
            : RouteNames.topUpSuccess;
    await context.pushNamed(
      route,
      extra: result,
      queryParameters:
          status == 'completed' ? const {'hideDone': '1'} : const {},
    );
    return;
  }

  if (type == 'wifi_package') {
    final title = detail.productName.trim().isEmpty
        ? 'history.tab_package'.tr()
        : detail.productName.trim();
    final result = status == 'failed'
        ? PackageBuyResult.failure(
            packageId: detail.productId,
            packageTitle: title,
            pricePoints: amount,
            autoRenew: false,
            transactionId: transactionId,
            speedMbps: detail.productSpeed,
            duration:
                _packageDuration(detail.monthCycle, detail.monthCycleUnit),
            occurredAt: detail.createdAt,
            errorTitleKey: 'package.result_failure_title',
            errorBodyKey: 'package.result_failure_body',
          )
        : PackageBuyResult.success(
            packageId: detail.productId,
            packageTitle: title,
            pricePoints: amount,
            autoRenew: false,
            transactionId: transactionId,
            speedMbps: detail.productSpeed,
            duration:
                _packageDuration(detail.monthCycle, detail.monthCycleUnit),
            occurredAt: detail.createdAt,
          );
    await context.pushNamed(
      status == 'failed'
          ? RouteNames.packageBuyFailure
          : RouteNames.packageBuySuccess,
      extra: result,
      queryParameters:
          status == 'completed' ? const {'hideDone': '1'} : const {},
    );
    return;
  }

  if (type == 'ftth_bill' || type == 'cg_bill') {
    final result = pending
        ? PayBillResult.pending(
            amountPoints: amount,
            account: detail.account,
            serviceType: detail.serviceType,
            productLabel: detail.productName,
            speed: detail.productSpeed,
            transactionId: transactionId,
            occurredAt: detail.createdAt,
            remark: detail.remark,
          )
        : PayBillResult.success(
            amountPoints: amount,
            account: detail.account,
            serviceType: detail.serviceType,
            productLabel: detail.productName,
            speed: detail.productSpeed,
            transactionId: transactionId,
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

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item, this.onTap});

  final HistoryModel item;
  final VoidCallback? onTap;

  String get _type => item.type.toLowerCase();

  bool get _isCredit =>
      item.isCredit ||
      (!item.isDebit && (_type == 'topup' || _type == 'refund'));

  String get _asset => switch (_type) {
        'topup' => QuickActionIconChip.topUpAsset,
        'wifi_package' => QuickActionIconChip.packageAsset,
        'ftth_bill' || 'cg_bill' => QuickActionIconChip.billAsset,
        _ => QuickActionIconChip.historyAsset,
      };

  Color get _iconBackground => switch (_type) {
        'topup' => QuickActionIconChip.topUpSoft,
        'wifi_package' => QuickActionIconChip.packageSoft,
        'ftth_bill' || 'cg_bill' => QuickActionIconChip.billSoft,
        _ => QuickActionIconChip.historySoft,
      };

  String get _fallbackTitleKey => switch (_type) {
        'topup' => 'history.item_topup_title',
        'wifi_package' => item.status.toLowerCase() == 'failed'
            ? 'history.item_package_fail_title'
            : 'history.item_package_success_title',
        'ftth_bill' || 'cg_bill' => 'history.item_bill_title',
        _ => 'history.tab_all',
      };

  String get _fallbackBodyKey => switch (_type) {
        'topup' => 'history.item_topup_body',
        'wifi_package' => item.status.toLowerCase() == 'failed'
            ? 'history.item_package_fail_body'
            : 'history.item_package_success_body',
        'ftth_bill' || 'cg_bill' => 'history.item_bill_body',
        _ => 'history.empty_body',
      };

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final title = item.titleCode.isNotEmpty
        ? MessageCodes.locKey(item.titleCode).tr()
        : _fallbackTitleKey.tr();
    final body = item.descriptionCode.isNotEmpty
        ? MessageCodes.locKeyBody(item.descriptionCode).tr()
        : _fallbackBodyKey.tr();
    final amount = item.amount == null
        ? '-'
        : '${_isCredit ? '+' : '-'}${NumberFormat('#,##0.##', 'en').format(item.amount)} ${'topup.pts'.tr()}';
    final date = formatDate(item.createdAt.toIso8601String());

    return AppCard(
      onTap: onTap,
      elevated: false,
      bordered: false,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      borderRadius: AppStyle.borderRadiusListCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuickActionIconChip(
            asset: _asset,
            background: _iconBackground,
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
                          fontSize: 15,
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
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _isCredit
                            ? AppColors.success
                            : const Color(0xFFD90000),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
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
          ),
        ],
      ),
    );
  }
}
