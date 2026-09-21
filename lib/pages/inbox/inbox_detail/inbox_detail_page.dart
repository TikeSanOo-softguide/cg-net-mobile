import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/inbox_category_icon/inbox_category_icon.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/user_model/user_model.dart';
import 'inbox_detail_controller.dart';

class InboxDetailPage extends ConsumerWidget {
  const InboxDetailPage({super.key, required this.id});

  final String id;

  static String _categoryLabel(InboxCategory category) {
    switch (category) {
      case InboxCategory.announcement:
        return 'inbox.tab_announcement'.tr();
      case InboxCategory.system:
        return 'inbox.tab_system'.tr();
      case InboxCategory.promotion:
        return 'inbox.tab_promotion'.tr();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final message = ref.watch(inboxDetailControllerProvider(id));

    return AppCurvedScaffold(
      title: Text('inbox.detail_title'.tr()),
      showBack: true,
      body: message.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (item) {
          final dateText = DateFormat.yMMMd(context.locale.toString())
              .add_jm()
              .format(item.createdAt);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              AppCard(
                elevated: false,
                bordered: false,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InboxCategoryIcon(category: item.category),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.titleKey.tr(),
                                style: AppTheme.english(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _categoryLabel(item.category),
                                      style: AppTheme.english(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.isRead
                                        ? 'inbox.status_read'.tr()
                                        : 'inbox.status_unread'.tr(),
                                    style: AppTheme.english(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: item.isRead
                                          ? AppColors.textMuted
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar_clock,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            dateText,
                            style: AppTheme.english(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: AppColors.borderLight),
                    const SizedBox(height: 14),
                    Text(
                      'inbox.detail_body_label'.tr(),
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (item.detailKey ?? item.bodyKey).tr(),
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
