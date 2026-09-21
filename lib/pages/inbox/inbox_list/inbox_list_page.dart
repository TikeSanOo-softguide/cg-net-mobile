import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/app_glass_tab_bar/app_glass_tab_bar.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/inbox_category_icon/inbox_category_icon.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/locale/app_locale_provider.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/user_model/user_model.dart';
import 'inbox_list_controller.dart';

class InboxListPage extends ConsumerStatefulWidget {
  const InboxListPage({super.key});

  @override
  ConsumerState<InboxListPage> createState() => _InboxListPageState();
}

class _InboxListPageState extends ConsumerState<InboxListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabLabels = [
    'inbox.tab_all',
    'inbox.tab_announcement',
    'inbox.tab_system',
    'inbox.tab_promotion',
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

  List<InboxMessageModel> _itemsForTab(
    List<InboxMessageModel> all,
    int index,
  ) {
    switch (index) {
      case 1:
        return all
            .where((e) => e.category == InboxCategory.announcement)
            .toList();
      case 2:
        return all.where((e) => e.category == InboxCategory.system).toList();
      case 3:
        return all
            .where((e) => e.category == InboxCategory.promotion)
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxListControllerProvider);
    final locale = ref.watch(appLocaleProvider);

    return AppCurvedScaffold(
      key: ValueKey('inbox-$locale'),
      title: Text('inbox.title'.tr()),
      showBack: false,
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
            child: state.when(
              loading: () =>
                  const ShimmerLoading(itemCount: 5, itemHeight: 88),
              error: (e, _) => EmptyState(
                title: 'common.error'.tr(),
                message: e.toString(),
                actionLabel: 'common.retry'.tr(),
                onAction: () => ref.invalidate(inboxListControllerProvider),
              ),
              data: (messages) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    for (var t = 0; t < 4; t++)
                      _InboxList(
                        key: ValueKey('inbox-list-$locale-$t'),
                        items: _itemsForTab(messages, t),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({super.key, required this.items});

  final List<InboxMessageModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyState(
        title: 'inbox.empty_title'.tr(),
        message: 'inbox.empty_body'.tr(),
        icon: LucideIcons.mail_open,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 5),
      itemBuilder: (context, index) {
        final item = items[index];
        return _InboxCard(
          item: item,
          onTap: () => context.pushNamed(
            RouteNames.inboxDetail,
            pathParameters: {'id': item.id},
          ),
        );
      },
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.onTap,
  });

  final InboxMessageModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !item.isRead;
    final locale = context.locale;

    return AppCard(
      onTap: onTap,
      elevated: true,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusSm,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (unread)
              Container(
                width: 4,
                color: AppColors.primary,
              ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(unread ? 12 : 14, 14, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InboxCategoryIcon(category: item.category),
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
                                  item.titleKey.tr(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.english(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primary,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.MMMd(locale.toString())
                                    .format(item.createdAt),
                                style: AppTheme.english(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: unread
                                      ? AppColors.primary
                                      : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.bodyKey.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
