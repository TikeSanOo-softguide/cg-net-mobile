import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/empty_state/empty_state.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import 'chat_list_controller.dart';

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('support.chat_list_title'.tr())),
      body: state.when(
        loading: () => const ShimmerLoading(itemCount: 4, itemHeight: 72),
        error: (e, _) => EmptyState(
          title: 'common.error'.tr(),
          message: e.toString(),
          actionLabel: 'common.retry'.tr(),
          onAction: () => ref.invalidate(chatListControllerProvider),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return EmptyState(
              title: 'support.empty_title'.tr(),
              message: 'support.empty_body'.tr(),
              icon: Icons.chat_bubble_outline,
            );
          }
          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.support_agent, color: AppColors.accent),
                ),
                title: Text(chat.title),
                subtitle: Text(
                  chat.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: chat.unreadCount > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: AppColors.secondary,
                        child: Text(
                          '${chat.unreadCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSecondary,
                          ),
                        ),
                      )
                    : null,
                onTap: () => context.pushNamed(
                  RouteNames.chatDetail,
                  pathParameters: {'id': chat.id},
                ),
              );
            },
          );
        },
      ),
    );
  }
}
