import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/empty_state/empty_state.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import 'inbox_list_controller.dart';

class InboxListPage extends ConsumerWidget {
  const InboxListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inboxListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('inbox.title'.tr())),
      body: state.when(
        loading: () => const ShimmerLoading(itemCount: 5, itemHeight: 72),
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
              icon: Icons.mail_outline,
            );
          }
          return ListView.separated(
            itemCount: messages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = messages[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                  child: Icon(
                    item.isRead ? Icons.mail_outline : Icons.mail,
                    color: AppColors.secondary,
                  ),
                ),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight:
                        item.isRead ? FontWeight.w500 : FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  item.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  DateFormat.MMMd().format(item.createdAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
