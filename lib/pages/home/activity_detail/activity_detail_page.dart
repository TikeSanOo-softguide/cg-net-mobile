import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Full activity detail — same card language as inbox detail.
class ActivityDetailPage extends StatelessWidget {
  const ActivityDetailPage({super.key, required this.item});

  final ActivityItem item;

  static const _creditGreen = Color(0xFF499A13);
  static const _debitRed = Color(0xFFFF0000);

  String get _kindLabel {
    switch (item.kind) {
      case ActivityKind.topUp:
        return 'history.tab_topup'.tr();
      case ActivityKind.transfer:
        return 'history.tab_transfer'.tr();
      case ActivityKind.bill:
        return 'history.tab_bill'.tr();
    }
  }

  Color get _amountColor {
    if (item.kind == ActivityKind.topUp || item.isCredit) {
      return _creditGreen;
    }
    return _debitRed;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final dateText =
        DateFormat.yMMMd(locale).add_jm().format(item.createdAt);
    final amountText =
        '${item.isCredit ? '+' : '-'}${NumberFormat('#,##0').format(item.amount)} Pts';

    return AppCurvedScaffold(
      title: Text('history.detail_title'.tr()),
      showBack: true,
      onBack: () => context.pop(),
      body: ListView(
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
                    ActivityListCard.kindIcon(item.kind),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.displayTitle(context),
                            style: AppTheme.english(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                              _kindLabel,
                              style: AppTheme.english(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
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
                  'history.detail_body_label'.tr(),
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.displaySubtitle(context),
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    amountText,
                    style: AppTheme.english(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _amountColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
