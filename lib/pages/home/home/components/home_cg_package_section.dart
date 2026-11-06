import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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

  static const _gap = 10.0;
  static const _listHeight = 214.0;
  static const _checkAsset = 'assets/images/packages/feature_check.png';

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Padding(
      padding: AppStyle.pagePaddingH,
      child: AppCard(
        elevated: false,
        bordered: false,
        borderRadius: AppStyle.borderRadiusSm,
        padding: const EdgeInsets.fromLTRB(10, 14, 10, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeSectionHeader(
              title: 'home.cg_package'.tr(),
              onSeeAll: () => context.goNamed(RouteNames.packageList),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - _gap) / 2;
                return SizedBox(
                  height: _listHeight,
                  child: ListView.separated(
                    key: ValueKey('cg-packages-$locale'),
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: _gap),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: cardWidth,
                        height: _listHeight,
                        child: _HomePackageCard(item: _items[index]),
                      );
                    },
                  ),
                );
              },
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

class _HomePackageCard extends StatelessWidget {
  const _HomePackageCard({required this.item});

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

    return Material(
      color: AppColors.primarySoft,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openDetail,
        splashColor: AppColors.primary.withValues(alpha: 0.05),
        highlightColor: AppColors.primary.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.speedMbps} Mbps',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.english(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 10),
              _MetaRow(
                label: 'home.pkg_month'.tr(),
                value: item.durationKey.tr(),
              ),
              const SizedBox(height: 6),
              _MetaRow(
                label: 'home.pkg_price'.tr(),
                value: '$price ${'topup.pts'.tr()}',
              ),
              const SizedBox(height: 8),
              _HomeFeature(label: 'package.feature_unlimited'.tr()),
              const SizedBox(height: 4),
              _HomeFeature(label: 'package.benefit_247'.tr()),
              const Spacer(),
              GestureDetector(
                onTap: openDetail,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'home.buy_now'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.english(
                      color: AppColors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: AppTheme.lineHeightMyanmarSafe,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
              height: AppTheme.lineHeightMyanmarSafe,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTheme.english(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              height: AppTheme.lineHeightMyanmarSafe,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeFeature extends StatelessWidget {
  const _HomeFeature({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          HomeCgPackageSection._checkAsset,
          width: 12,
          height: 12,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: AppTheme.lineHeightMyanmarSafe,
            ),
          ),
        ),
      ],
    );
  }
}
