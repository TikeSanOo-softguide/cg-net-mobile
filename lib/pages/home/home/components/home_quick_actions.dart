import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/quick_action_icon_chip/quick_action_icon_chip.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../bound_broadband_provider.dart';
import 'home_header.dart';

class HomeQuickActions extends ConsumerWidget {
  const HomeQuickActions({super.key});

  /// Card block height used to center on the balance curve.
  static const double cardHeight = 60;
  static const double hangBelow = cardHeight / 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final bound = ref.watch(boundBroadbandProvider);
    final actions = [
      (
        QuickActionIconChip.topUpAsset,
        context.tr('home.action_topup'),
        RouteNames.topUp,
        QuickActionIconChip.topUpSoft,
        AppColors.primary,
        false,
      ),
      (
        QuickActionIconChip.historyAsset,
        context.tr('home.action_history'),
        RouteNames.history,
        QuickActionIconChip.historySoft,
        null,
        false,
      ),
      (
        QuickActionIconChip.bindAsset,
        context.tr('home.action_account'),
        '',
        QuickActionIconChip.bindSoft,
        AppColors.success,
        true,
      ),
    ];

    return Container(
      key: ValueKey('quick-actions-$locale'),
      margin: AppStyle.pagePaddingH,
      decoration: BoxDecoration(
        borderRadius: AppStyle.borderRadiusSm,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyle.borderRadiusSm,
          side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 34,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    color: AppColors.borderLight,
                  ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (actions[i].$6) {
                          onHomeBindTap(context, ref);
                          return;
                        }
                        context.pushNamed(actions[i].$3);
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: SizedBox(
                        height: 44,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            QuickActionIconChip(
                              asset: actions[i].$1,
                              background: actions[i].$4,
                              tint: actions[i].$5,
                              size: 34,
                              iconSize: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                actions[i].$2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.captionSm(
                                  color: AppColors.textMuted,
                                ).copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  height: AppStyle.lineHeightBody,
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
        ),
      ),
    );
  }
}
