import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_filter_drawer/activity_filter_drawer.dart';
import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_glass_tab_bar/app_glass_tab_bar.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/router/route_names/route_names.dart';

/// History — tabs: All / Top-Up / Transfer / Bill.
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
    'history.tab_transfer',
    'history.tab_bill',
  ];

  List<ActivityItem> get _allItems => [
        ActivityItem(
          id: 'h1',
          kind: ActivityKind.topUp,
          titleKey: 'history.item_topup_title',
          subtitleKey: 'history.item_topup_body',
          amount: 2500,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isCredit: true,
        ),
        ActivityItem(
          id: 'h2',
          kind: ActivityKind.transfer,
          title: '09970071489',
          subtitleKey: 'history.item_transfer_body',
          amount: 500,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        ActivityItem(
          id: 'h3',
          kind: ActivityKind.bill,
          titleKey: 'history.item_bill_title',
          subtitleKey: 'history.item_bill_body',
          amount: 18000,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ActivityItem(
          id: 'h4',
          kind: ActivityKind.topUp,
          titleKey: 'history.item_topup_title',
          subtitleKey: 'history.item_topup_body',
          amount: 100,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isCredit: true,
        ),
        ActivityItem(
          id: 'h5',
          kind: ActivityKind.transfer,
          title: '09791234567',
          subtitleKey: 'history.item_transfer_body',
          amount: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        ActivityItem(
          id: 'h6',
          kind: ActivityKind.bill,
          titleKey: 'history.item_bill_title',
          subtitleKey: 'history.item_bill_body',
          amount: 12000,
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
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

  List<ActivityItem> _itemsForTab(int index) {
    Iterable<ActivityItem> filtered = _allItems;
    switch (index) {
      case 1:
        filtered = _allItems.where((e) => e.kind == ActivityKind.topUp);
      case 2:
        filtered = _allItems.where((e) => e.kind == ActivityKind.transfer);
      case 3:
        filtered = _allItems.where((e) => e.kind == ActivityKind.bill);
    }
    return filtered.where((e) => _filter.matches(e.createdAt)).toList();
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
                    items: _itemsForTab(t),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({super.key, required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        title: 'history.empty_title'.tr(),
        message: 'history.empty_body'.tr(),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        return ActivityListCard(
          item: items[index],
          index: index,
          onTap: () => context.pushNamed(
            RouteNames.activityDetail,
            extra: items[index],
          ),
        );
      },
    );
  }
}
