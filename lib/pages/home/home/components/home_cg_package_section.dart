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

  static const _cardWidth = 148.0;
  static const _listHeight = 206.0;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Padding(
      padding: AppStyle.pagePaddingH,
      child: AppCard(
        elevated: false,
        bordered: false,
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
              height: _listHeight,
              child: ListView.separated(
                key: ValueKey('cg-packages-$locale'),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
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
    final features = <String>[
      'home.feat_dedicated'.tr(),
      'home.feat_bandwidth'.tr(namedArgs: {'speed': item.speedMbps}),
      'home.feat_unlimited'.tr(),
      'home.feat_fiber'.tr(),
    ];

    void openDetail() {
      context.pushNamed(
        RouteNames.packageDetail,
        pathParameters: {'id': item.id},
      );
    }

    const radius = AppStyle.radiusSm;

    return SizedBox(
      width: HomeCgPackageSection._cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: openDetail,
          borderRadius: BorderRadius.circular(radius),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Stack(
                children: [
                  Positioned(
                    right: -28,
                    top: -36,
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.onPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20,
                    bottom: 36,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.onPrimary.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.onPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              item.durationKey.tr().toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.english(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                height: AppTheme.lineHeightMyanmarSafe,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.english(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimary,
                            height: 1.05,
                            letterSpacing: -0.6,
                          ),
                        ),
                        Text(
                          'topup.pts'.tr(),
                          style: AppTheme.english(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimary.withValues(alpha: 0.78),
                            height: AppTheme.lineHeightMyanmarSafe,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        for (final feature in features) _FeatureLine(text: feature),
                        const Spacer(),
                        SizedBox(
                          height: 28,
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: openDetail,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: AppColors.onAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size.fromHeight(28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            child: Text(
                              'home.buy_now'.tr(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.english(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onAccent,
                                height: AppTheme.lineHeightMyanmarSafe,
                                letterSpacing: 0,
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
          ),
        ),
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              LucideIcons.circle_check,
              size: 12,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.english(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.onPrimary,
                height: AppTheme.lineHeightMyanmarSafe,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
