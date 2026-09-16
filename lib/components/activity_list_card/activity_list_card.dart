import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';
import '../app_card/app_card.dart';

enum ActivityKind { topUp, transfer, bill }

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.createdAt,
    this.isCredit = false,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String subtitle;
  final int amount;
  final DateTime createdAt;
  final bool isCredit;
}

/// Inbox-like activity row used by History + Transfer recent list.
class ActivityListCard extends StatelessWidget {
  const ActivityListCard({
    super.key,
    required this.item,
    required this.index,
    this.onTap,
    this.amountColor,
  });

  final ActivityItem item;
  final int index;
  final VoidCallback? onTap;
  final Color? amountColor;

  static const _creditGreen = Color(0xFF15803D);
  static const _debitRed = Color(0xFFDC2626);

  static (IconData, Color, Color) _styleFor(ActivityKind kind) {
    switch (kind) {
      case ActivityKind.topUp:
        return (LucideIcons.wallet, const Color(0xFFE0E7FF), AppColors.primary);
      case ActivityKind.transfer:
        return (
          LucideIcons.arrow_left_right,
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
        );
      case ActivityKind.bill:
        return (
          LucideIcons.circle_dollar_sign,
          const Color(0xFFFFF3C4),
          const Color(0xFFCA8A04),
        );
    }
  }

  Color get _resolvedAmountColor {
    if (amountColor != null) return amountColor!;
    if (item.kind == ActivityKind.topUp || item.isCredit) {
      return _creditGreen;
    }
    return _debitRed;
  }

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(item.kind);
    final amountText =
        '${item.isCredit ? '+' : '-'}${NumberFormat('#,##0').format(item.amount)} Pts';

    return AppCard(
      onTap: onTap,
      elevated: true,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusMd,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                            fontWeight: FontWeight.w700,
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
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        amountText,
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _resolvedAmountColor,
                        ),
                      ),
                    ],
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
