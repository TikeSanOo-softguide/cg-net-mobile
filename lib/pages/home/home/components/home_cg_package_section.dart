import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../components/app_card/app_card.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import 'home_section_header.dart';

class HomeCgPackageSection extends StatelessWidget {
  const HomeCgPackageSection({super.key});

  static const _items = <_CgPackage>[
    _CgPackage(
      id: '1m',
      speedMbps: '20',
      pricePoints: 15000,
      durationKey: 'package.duration_1m',
    ),
    _CgPackage(
      id: '3m',
      speedMbps: '20',
      pricePoints: 40000,
      durationKey: 'package.duration_3m',
    ),
    _CgPackage(
      id: '6m',
      speedMbps: '30',
      pricePoints: 75000,
      durationKey: 'package.duration_6m',
    ),
    _CgPackage(
      id: '1y',
      speedMbps: '30',
      pricePoints: 140000,
      durationKey: 'package.duration_12m',
    ),
    _CgPackage(
      id: '1m_extra',
      speedMbps: '20',
      pricePoints: 15000,
      durationKey: 'package.duration_1m',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppStyle.pagePaddingH,
      child: AppCard(
        elevated: false,
        bordered: false,
        color: AppColors.primarySoft,
        borderRadius: AppStyle.borderRadiusSm,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeSectionHeader(
              title: 'home.cg_package'.tr(),
              onSeeAll: () => context.goNamed(RouteNames.packageList),
            ),
            SizedBox(
              height: 136,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return _CgPackageCard(item: _items[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CgPackage {
  const _CgPackage({
    required this.id,
    required this.speedMbps,
    required this.pricePoints,
    required this.durationKey,
  });

  final String id;
  final String speedMbps;
  final int pricePoints;
  final String durationKey;
}

class _CgPackageCard extends StatelessWidget {
  const _CgPackageCard({required this.item});

  final _CgPackage item;

  @override
  Widget build(BuildContext context) {
    final price = NumberFormat('#,##0').format(item.pricePoints);
    void openDetail() {
      context.pushNamed(
        RouteNames.packageDetail,
        pathParameters: {'id': item.id},
      );
    }

    return SizedBox(
      width: 220,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: openDetail,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.gauge,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: item.speedMbps,
                              style: AppTheme.english(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                height: 1.05,
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text: ' Mbps',
                              style: AppTheme.english(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                                height: 1.05,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          item.durationKey.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            height: AppTheme.lineHeightMyanmarSafe,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _FactLine(
                  label: 'home.pkg_price'.tr(),
                  value: '$price ${'topup.pts'.tr()}',
                  valueSize: 14,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'home.pkg_install'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.english(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          height: AppTheme.lineHeightMyanmarSafe,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          'home.install_fee_free'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            height: AppTheme.lineHeightMyanmarSafe,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: openDetail,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size.fromHeight(28),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'home.buy_now'.tr(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onPrimary,
                        height: AppTheme.lineHeightMyanmarSafe,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FactLine extends StatelessWidget {
  const _FactLine({
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.valueSize = 13,
  });

  final String label;
  final String value;
  final Color valueColor;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.english(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: AppTheme.english(
              fontSize: valueSize,
              fontWeight: FontWeight.w700,
              color: valueColor,
              height: AppTheme.lineHeightMyanmarSafe,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
