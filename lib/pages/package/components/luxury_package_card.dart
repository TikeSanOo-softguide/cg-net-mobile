import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Simple white package card — speed, title, price, buy.
class LuxuryPackageCard extends StatelessWidget {
  const LuxuryPackageCard({
    super.key,
    required this.title,
    required this.priceLabel,
    required this.periodLabel,
    required this.speedLabel,
    required this.onBuy,
    this.onTap,
    this.popular = false,
    this.showBenefits = true,
    this.footer,
  });

  final String title;
  final String priceLabel;
  final String periodLabel;
  final String speedLabel;
  final VoidCallback onBuy;
  final VoidCallback? onTap;
  final bool popular;
  final bool showBenefits;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.05),
        highlightColor: AppColors.primary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      speedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        height: 1.1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (popular)
                          Text(
                            'package.popular_plan'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              height: AppTheme.lineHeightMyanmarSafe,
                            ),
                          ),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                            height: AppTheme.lineHeightMyanmarSafe,
                          ),
                        ),
                        Text(
                          'package.unlimited_internet'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textMuted,
                            height: AppTheme.lineHeightMyanmarSafe,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        priceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        periodLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          height: AppTheme.lineHeightMyanmarSafe,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onBuy,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'home.buy_now'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                              height: AppTheme.lineHeightMyanmarSafe,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (showBenefits) ...[
                const SizedBox(height: 8),
                Text(
                  '${'package.benefit_no_limit'.tr()}  ·  ${'package.benefit_247'.tr()}  ·  ${'package.benefit_monthly'.tr()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                    height: AppTheme.lineHeightMyanmarSafe,
                  ),
                ),
              ],
              if (footer != null) ...[
                const SizedBox(height: 10),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
