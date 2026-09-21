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
    required this.amount,
    required this.createdAt,
    this.title,
    this.titleKey,
    this.subtitle,
    this.subtitleKey,
    this.isCredit = false,
  }) : assert(
          title != null || titleKey != null,
          'Provide title or titleKey',
        ),
        assert(
          subtitle != null || subtitleKey != null,
          'Provide subtitle or subtitleKey',
        );

  final String id;
  final ActivityKind kind;
  final String? title;
  final String? titleKey;
  final String? subtitle;
  final String? subtitleKey;
  final int amount;
  final DateTime createdAt;
  final bool isCredit;

  String displayTitle(BuildContext context) {
    if (titleKey != null) return context.tr(titleKey!);
    return title ?? '';
  }

  String displaySubtitle(BuildContext context) {
    if (subtitleKey != null) return context.tr(subtitleKey!);
    return subtitle ?? '';
  }
}

/// Activity row — 2-line detail with … ; amount bottom-right; tap opens detail.
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

  static IconData iconFor(ActivityKind kind) {
    switch (kind) {
      case ActivityKind.topUp:
        return LucideIcons.wallet;
      case ActivityKind.transfer:
        return LucideIcons.arrow_left_right;
      case ActivityKind.bill:
        return LucideIcons.circle_dollar_sign;
    }
  }

  Color get _resolvedAmountColor {
    if (amountColor != null) return amountColor!;
    if (item.kind == ActivityKind.topUp || item.isCredit) {
      return _creditGreen;
    }
    return _debitRed;
  }

  String get amountText =>
      '${item.isCredit ? '+' : '-'}${NumberFormat('#,##0').format(item.amount)} Pts';

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;

    return AppCard(
      key: ValueKey('activity-card-${item.id}-${locale.languageCode}'),
      onTap: onTap,
      elevated: true,
      bordered: false,
      padding: EdgeInsets.zero,
      borderRadius: AppStyle.borderRadiusSm,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 35,
              height: 35,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppStyle.borderRadiusSm,
              ),
              child: Icon(
                iconFor(item.kind),
                color: AppColors.onPrimary,
                size: 18,
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
                          item.displayTitle(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
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
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.displaySubtitle(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      amountText,
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _resolvedAmountColor,
                      ),
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
