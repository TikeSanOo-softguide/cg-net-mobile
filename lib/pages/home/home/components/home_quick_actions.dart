import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/app_card/app_card.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;
    final actions = [
      (
        LucideIcons.wallet,
        context.tr('home.action_topup'),
        RouteNames.topUp,
      ),
      (
        LucideIcons.arrow_left_right,
        context.tr('home.action_transfer'),
        RouteNames.transfer,
      ),
      (
        LucideIcons.clipboard_clock,
        context.tr('home.action_history'),
        RouteNames.history,
      ),
    ];

    return AppCard(
      key: ValueKey('quick-actions-$locale'),
      margin: AppStyle.pagePaddingH,
      elevated: true,
      bordered: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyle.spaceSm,
        vertical: 7,
      ),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: AppColors.borderLight,
              ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.pushNamed(actions[i].$3),
                  borderRadius: BorderRadius.circular(8),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: SizedBox(
                    height: 38,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: AppStyle.iconChipDecoration(),
                          child: Icon(
                            actions[i].$1,
                            color: AppColors.primary,
                            size: 16,
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
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
