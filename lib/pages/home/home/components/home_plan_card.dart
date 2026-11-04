import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/app_card/app_card.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

/// Home row for the active plan. Opens the subscription detail page.
class HomePlanCard extends StatelessWidget {
  const HomePlanCard({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  void _openDetail(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    context.pushNamed(RouteNames.subscriptionDetail);
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return AppCard(
      margin: AppStyle.pagePaddingH,
      elevated: false,
      bordered: false,
      borderRadius: AppStyle.borderRadiusMd,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => _openDetail(context),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              LucideIcons.box,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'home.my_subscription'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.english(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: AppTheme.lineHeightMyanmarSafe,
              ),
            ),
          ),
          const Icon(
            LucideIcons.chevron_right,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
