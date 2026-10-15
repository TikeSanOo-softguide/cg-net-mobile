import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_filter_drawer/activity_filter_drawer.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_glass_tab_bar/app_glass_tab_bar.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../data/history/history_repository.dart';
import '../../../models/history_model/history_model.dart';

final transactionHistoryProvider =
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
    final history = ref.watch(transactionHistoryProvider(type));

    return history.when(
      data: (items) {
        final filteredItems = items
            .where((item) => filter.matches(item.createdAt.toLocal()))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        if (filteredItems.isEmpty) return _emptyState();

        final groupedItems = <DateTime, List<HistoryModel>>{};
        for (final item in filteredItems) {
          final createdAt = item.createdAt.toLocal();
          final date = DateTime(createdAt.year, createdAt.month, createdAt.day);
          groupedItems.putIfAbsent(date, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            for (final group in groupedItems.entries) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: _HistoryDateHeader(date: group.key),
              ),
              for (final item in group.value) ...[
                _HistoryRow(item: item),
                const SizedBox(height: 5),
              ],
            ],
          ],
        );
      },
      loading: () => const ShimmerLoading(itemCount: 5, itemHeight: 88),
      error: (error, _) => EmptyState(
        title: isOfflineError(error)
            ? 'shared.no_internet_title'.tr()
            : 'common.error'.tr(),
        message: isOfflineError(error)
            ? 'shared.no_internet_body'.tr()
            : apiErrorText(error),
        actionLabel: 'common.retry'.tr(),
        onAction: () async {
          final recoveryKey = 'history-${type ?? 'all'}-reload';
          if (isOfflineError(error)) {
            ref.read(networkRecoveryControllerProvider).enqueue(
                  recoveryKey,
                  () async => ref.invalidate(transactionHistoryProvider(type)),
                );
            final shouldRetry = await openNoInternetPage(context);
            if (shouldRetry == true && context.mounted) {
              ref.read(networkRecoveryControllerProvider).clear(recoveryKey);
              ref.invalidate(transactionHistoryProvider(type));
            }
            return;
          }
          ref.invalidate(transactionHistoryProvider(type));
        },
      ),
    );
  }

  Widget _emptyState() => EmptyState(
        title: 'history.empty_title'.tr(),
        message: 'history.empty_body'.tr(),
      );
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});

  final HistoryModel item;

  String get _titleKey => switch (item.type.toLowerCase()) {
        'topup' => 'history.tab_topup',
        'wifi_package' => 'history.tab_package',
        'ftth_bill' => 'history.tab_bill',
        _ => 'history.tab_all',
      };

  String get _asset => switch (item.type.toLowerCase()) {
        'topup' => QuickActionIconChip.topUpAsset,
        'wifi_package' => QuickActionIconChip.packageAsset,
        'ftth_bill' => QuickActionIconChip.billAsset,
        _ => QuickActionIconChip.historyAsset,
      };

  Color get _iconBackground => switch (item.type.toLowerCase()) {
        'topup' => QuickActionIconChip.topUpSoft,
        'wifi_package' => QuickActionIconChip.packageSoft,
        'ftth_bill' => QuickActionIconChip.billSoft,
        _ => QuickActionIconChip.historySoft,
      };

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;
    final amount = item.amount == null
        ? '-'
        : NumberFormat('#,##0.##', locale.toString()).format(item.amount);
    final transactionNo = item.transactionNo?.trim();

    return AppCard(
      elevated: true,
      bordered: false,
      padding: const EdgeInsets.all(14),
      child: Row(
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
                Text(
                  item.description.isEmpty ? _titleKey.tr() : item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'history.amount'.tr()}: $amount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                if (transactionNo != null && transactionNo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${'history.transaction_no'.tr()}: $transactionNo',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDateHeader extends StatelessWidget {
  const _HistoryDateHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final headerDate = DateUtils.dateOnly(date);
    final relativeLabel = headerDate == today
        ? 'history.today'.tr()
        : headerDate == today.subtract(const Duration(days: 1))
            ? 'history.yesterday'.tr()
            : null;
    final formattedDate =
        DateFormat('MM/dd/yyyy (EEEE)', context.locale.toString()).format(date);

    return Text(
      relativeLabel == null ? formattedDate : '$relativeLabel $formattedDate',
      style: AppTheme.english(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
      ),
    );
  }
}
