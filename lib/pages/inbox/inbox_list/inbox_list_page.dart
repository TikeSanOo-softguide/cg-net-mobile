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
import '../../../core/network/api_error_text.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
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
        return all.where((e) => e.category == InboxCategory.promotion).toList();
      default:
        return all;
    }
  }

  static String _emptyIconForTab(int index) {
    switch (index) {
      case 2:
        return InboxCategoryIcon.settingsAsset;
      case 3:
        return InboxCategoryIcon.promotionAsset;
      default:
        return InboxCategoryIcon.messageAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inboxListControllerProvider);
    final offline = ref.watch(inboxListOfflineProvider);
    final locale = ref.watch(appLocaleProvider);
    ref.listen(inboxListOfflineProvider, (previous, next) {
      _syncInboxRecovery(ref, next);
    });
    ref.listen(inboxListControllerProvider, (previous, next) {
      if (next.hasError && isOfflineError(next.error) && !next.hasValue) {
        _syncInboxRecovery(ref, true);
      }
    });

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
          if (offline && state.hasValue)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _InboxOfflineLine(),
            ),
          Expanded(
            child: state.when(
              loading: () => const ShimmerLoading(itemCount: 5, itemHeight: 88),
              error: (e, _) => EmptyState(
                icon: LucideIcons.wifi_off,
                iconAsset:
                    isOfflineError(e) ? null : InboxCategoryIcon.messageAsset,
                title: isOfflineError(e)
                    ? 'shared.no_internet_title'.tr()
                    : 'common.error'.tr(),
                message: isOfflineError(e)
                    ? 'shared.no_internet_body'.tr()
                    : apiErrorText(e),
                actionLabel: 'common.retry'.tr(),
                onAction: () {
                  ref.read(inboxListControllerProvider.notifier).load();
                },
              ),
              data: (messages) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    for (var t = 0; t < 4; t++)
                      _InboxList(
                        key: ValueKey('inbox-list-$locale-$t'),
                        items: _itemsForTab(messages, t),
                        emptyIcon: _emptyIconForTab(t),
                        onRefresh: () => ref
                            .read(inboxListControllerProvider.notifier)
                            .load(silent: true),
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

void _syncInboxRecovery(WidgetRef ref, bool waitingForNetwork) {
  const key = 'inbox-list-reload';
  final recovery = ref.read(networkRecoveryControllerProvider);
  if (!waitingForNetwork) {
    recovery.clear(key);
    return;
  }
  recovery.enqueue(
    key,
    () => ref.read(inboxListControllerProvider.notifier).load(
          silent: true,
          rethrowOffline: true,
        ),
  );
}

class _InboxOfflineLine extends StatelessWidget {
  const _InboxOfflineLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'shared.no_internet_title'.tr(),
        textAlign: TextAlign.center,
        style: AppTheme.caption(
          color: AppColors.primary,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InboxList extends StatelessWidget {
  const _InboxList({
    super.key,
    required this.items,
    required this.emptyIcon,
    required this.onRefresh,
  });

  final List<InboxMessageModel> items;
  final String emptyIcon;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _InboxEmpty(iconAsset: emptyIcon),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
      ),
    );
  }
}

class _InboxEmpty extends StatelessWidget {
  const _InboxEmpty({required this.iconAsset});

  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: AppStyle.borderRadiusLg,
              ),
              child: Image.asset(
                iconAsset,
                width: 40,
                height: 40,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'inbox.empty_title'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.body(
                color: AppColors.primary,
                weight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'inbox.empty_body'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.caption(),
            ),
          ],
        ),
      ),
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
      elevated: false,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  InboxCategoryIcon(
                    category: item.category,
                    isFailure: item.isFailure,
                  ),
                  if (unread)
                    const Positioned(
                      top: -2,
                      left: -2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.surface, width: 1.5),
                          ),
                        ),
                        child: SizedBox(width: 10, height: 10),
                      ),
                    ),
                ],
              ),
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
                          item.titles == null
                              ? item.titleKey.tr()
                              : item.titleFor(locale.languageCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 16,
                            fontWeight:
                                unread ? FontWeight.w600 : FontWeight.w400,
                            letterSpacing:
                                locale.languageCode == 'my' ? 0 : 0.2,
                            color: item.isFailure
                                ? InboxCategoryIcon.failureColor
                                : AppColors.primary,
                            height: locale.languageCode == 'my'
                                ? AppTheme.lineHeightMyanmarSafe
                                : 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.MMMd(locale.toString())
                            .format(item.createdAt),
                        style: AppTheme.english(
                          fontSize: 11,
                          fontWeight:
                              unread ? FontWeight.w600 : FontWeight.w500,
                          color:
                              unread ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.bodies == null
                        ? item.bodyKey.tr()
                        : item.bodyFor(locale.languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      fontSize: 14,
                      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
                      letterSpacing: 0,
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
    );
  }
}
