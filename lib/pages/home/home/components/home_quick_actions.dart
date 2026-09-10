import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final actions = [
      (LucideIcons.wallet, context.tr('home.action_topup')),
      (LucideIcons.arrow_left_right, context.tr('home.action_transfer')),
      (LucideIcons.clipboard_clock, context.tr('home.action_history')),
    ];

    return Container(
      key: ValueKey('quick-actions-$locale'),
      margin: AppStyle.pagePaddingH,
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyle.spaceSm,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppStyle.borderRadiusMd,
        boxShadow: AppStyle.cardShadowElevated,
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 32,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: AppColors.borderLight,
              ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: AppStyle.iconChipDecoration(),
                    child: Icon(
                      actions[i].$1,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      actions[i].$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.captionSm(color: AppColors.primary)
                          .copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
