import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/user_model/user_model.dart';
import 'inbox_list_controller.dart';

class InboxListPage extends ConsumerWidget {
  const InboxListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxListControllerProvider);

    return AppCurvedScaffold(
      title: Text('inbox.title'.tr()),
      showBack: false,
      body: state.when(
        loading: () => const ShimmerLoading(itemCount: 5, itemHeight: 88),
        error: (e, _) => EmptyState(
          title: 'common.error'.tr(),
          message: e.toString(),
          actionLabel: 'common.retry'.tr(),
          onAction: () => ref.invalidate(inboxListControllerProvider),
        ),
        data: (messages) {
          if (messages.isEmpty) {
            return EmptyState(
              title: 'inbox.empty_title'.tr(),
              message: 'inbox.empty_body'.tr(),
              icon: LucideIcons.mail_open,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: messages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = messages[index];
              return _InboxCard(
                item: item,
                index: index,
                onTap: () => context.pushNamed(
                  RouteNames.inboxDetail,
                  pathParameters: {'id': item.id},
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  final InboxMessageModel item;
  final int index;
  final VoidCallback onTap;

  static const _iconStyles = [
    (LucideIcons.clipboard_clock, Color(0xFFFFF3C4), Color(0xFFB45309)),
    (LucideIcons.settings, Color(0xFFFFE4E6), Color(0xFFE11D48)),
    (LucideIcons.megaphone, Color(0xFFEDE9FE), Color(0xFF7C3AED)),
    (LucideIcons.mail, AppColors.primaryLight, AppColors.primary),
    (LucideIcons.bell, Color(0xFFDCFCE7), Color(0xFF15803D)),
  ];

  @override
  Widget build(BuildContext context) {
    final style = _iconStyles[index % _iconStyles.length];
    final unread = !item.isRead;

    return AppCard(
      onTap: onTap,
      elevated: true,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusMd,
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
                padding: EdgeInsets.fromLTRB(unread ? 12 : 14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: style.$2,
                        borderRadius: AppStyle.borderRadiusSm,
                      ),
                      child: Icon(style.$1, color: style.$3, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.english(
                                    fontSize: 13,
                                    fontWeight: unread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.MMMd().format(item.createdAt),
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
                            item.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              height: 1.35,
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
