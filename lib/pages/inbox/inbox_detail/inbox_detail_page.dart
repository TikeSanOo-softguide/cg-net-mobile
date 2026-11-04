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
import '../inbox_list/inbox_list_controller.dart';
import 'inbox_detail_controller.dart';

class InboxDetailPage extends ConsumerStatefulWidget {
  const InboxDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<InboxDetailPage> createState() => _InboxDetailPageState();
}

class _InboxDetailPageState extends ConsumerState<InboxDetailPage> {
  var _markedRead = false;

  void _markReadIfNeeded(InboxMessageModel item) {
    if (_markedRead || item.isRead || int.tryParse(item.id) == null) return;
    _markedRead = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(inboxListControllerProvider.notifier).markRead(item.id);
    });
  }

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
  Widget build(BuildContext context) {
    final message = ref.watch(inboxDetailControllerProvider(widget.id));
    message.whenData(_markReadIfNeeded);

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
          final isMy = context.locale.languageCode == 'my';
          final accent = item.isFailure
              ? InboxCategoryIcon.failureColor
              : AppColors.primary;
          final accentSoft = item.isFailure
              ? InboxCategoryIcon.failureSoft
              : AppColors.primaryLight;
          final imageUrl = item.imageUrl?.trim();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              AppCard(
                elevated: true,
                bordered: false,
                borderRadius: AppStyle.borderRadiusMd,
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppStyle.radiusMd),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: AppColors.primaryLight,
                              child: Center(
                                child: Icon(
                                  LucideIcons.image,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InboxCategoryIcon(
                                category: item.category,
                                isFailure: item.isFailure,
                                size: 28,
                                iconSize: 16,
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: accentSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _categoryLabel(item.category),
                                  style: AppTheme.english(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: isMy ? 0 : 0.2,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            item.titles == null
                                ? item.titleKey.tr()
                                : item.titleFor(context.locale.languageCode),
                            style: AppTheme.english(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: isMy ? 0 : 0.2,
                              color: accent,
                              height:
                                  isMy ? AppTheme.lineHeightMyanmarSafe : 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateText,
                            style: AppTheme.english(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.backgroundAlt,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(14, 14, 14, 16),
                              child: Text(
                                item.bodies == null
                                    ? (item.detailKey ?? item.bodyKey).tr()
                                    : item.bodyFor(
                                        context.locale.languageCode,
                                      ),
                                style: AppTheme.english(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0,
                                  color: AppColors.textPrimary,
                                  height: 1.65,
                                ),
                              ),
                            ),
                          ),
                        ],
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
