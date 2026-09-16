import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_glass_tab_bar/app_glass_tab_bar.dart';
import '../../../components/empty_state/empty_state.dart';

/// History — tabs: All / Top-Up / Transfer / Bill.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  List<ActivityItem> get _allItems => [
        ActivityItem(
          id: 'h1',
          kind: ActivityKind.topUp,
          title: 'history.item_topup_title'.tr(),
          subtitle: 'history.item_topup_body'.tr(),
          amount: 2500,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          isCredit: true,
        ),
        ActivityItem(
          id: 'h2',
          kind: ActivityKind.transfer,
          title: '09970071489',
          subtitle: 'history.item_transfer_body'.tr(),
          amount: 500,
          createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        ),
        ActivityItem(
          id: 'h3',
          kind: ActivityKind.bill,
          title: 'history.item_bill_title'.tr(),
          subtitle: 'history.item_bill_body'.tr(),
          amount: 18000,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ActivityItem(
          id: 'h4',
          kind: ActivityKind.topUp,
          title: 'history.item_topup_title'.tr(),
          subtitle: 'history.item_topup_body'.tr(),
          amount: 100,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          isCredit: true,
        ),
        ActivityItem(
          id: 'h5',
          kind: ActivityKind.transfer,
          title: '09791234567',
          subtitle: 'history.item_transfer_body'.tr(),
          amount: 50,
          createdAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        ActivityItem(
          id: 'h6',
          kind: ActivityKind.bill,
          title: 'history.item_bill_title'.tr(),
          subtitle: 'history.item_bill_body'.tr(),
          amount: 12000,
          createdAt: DateTime.now().subtract(const Duration(days: 6)),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ActivityItem> _itemsForTab(int index) {
    switch (index) {
      case 1:
        return _allItems.where((e) => e.kind == ActivityKind.topUp).toList();
      case 2:
        return _allItems
            .where((e) => e.kind == ActivityKind.transfer)
            .toList();
      case 3:
        return _allItems.where((e) => e.kind == ActivityKind.bill).toList();
      default:
        return _allItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCurvedScaffold(
      title: Text('history.title'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: AppGlassTabBar(
              controller: _tabController,
              labels: const [
                'history.tab_all',
                'history.tab_topup',
                'history.tab_transfer',
                'history.tab_bill',
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (var t = 0; t < 4; t++)
                  _HistoryList(items: _itemsForTab(t)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({required this.items});

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
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return ActivityListCard(
          item: items[index],
          index: index,
        );
      },
    );
  }
}
