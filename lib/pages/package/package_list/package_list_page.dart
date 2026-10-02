import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Packages tab — compact horizontal list cards (reference design).
class PackageListPage extends StatelessWidget {
  const PackageListPage({super.key});

  static const _cards = <_PackageListData>[
    _PackageListData(
      id: '1m',
      imagePath: 'assets/images/packages/package_1m.png',
      titleKey: 'package.item_1m_title',
      badgeKey: 'package.badge_popular',
      badgeTone: _BadgeTone.popular,
      speedMbps: '20',
      pricePoints: 15000,
      durationKey: 'package.duration_1m',
      featureKeys: [
        'package.feature_router',
        'package.feature_unlimited',
        'package.feature_anywhere',
      ],
    ),
    _PackageListData(
      id: '3m',
      imagePath: 'assets/images/packages/package_3m.png',
      titleKey: 'package.item_3m_title',
      badgeKey: null,
      badgeTone: _BadgeTone.none,
      speedMbps: '20',
      pricePoints: 40000,
      durationKey: 'package.duration_3m',
      featureKeys: [
        'package.feature_speed',
        'package.feature_unlimited',
        'package.feature_term',
      ],
    ),
    _PackageListData(
      id: '6m',
      imagePath: 'assets/images/packages/package_6m.png',
      titleKey: 'package.item_6m_title',
      badgeKey: 'package.badge_trending',
      badgeTone: _BadgeTone.trending,
      speedMbps: '30',
      pricePoints: 75000,
      durationKey: 'package.duration_6m',
      featureKeys: [
        'package.feature_speed',
        'package.feature_term',
        'package.feature_router',
      ],
    ),
    _PackageListData(
      id: '1y',
      imagePath: 'assets/images/packages/package_1y.png',
      titleKey: 'package.item_1y_title',
      badgeKey: null,
      badgeTone: _BadgeTone.none,
      speedMbps: '30',
      pricePoints: 140000,
      durationKey: 'package.duration_12m',
      featureKeys: [
        'package.feature_unlimited',
        'package.feature_anywhere',
        'package.feature_term',
      ],
    ),
    _PackageListData(
      id: '1m_b',
      imagePath: 'assets/images/packages/package_1m.png',
      titleKey: 'package.item_1m_title',
      badgeKey: null,
      badgeTone: _BadgeTone.none,
      speedMbps: '20',
      pricePoints: 15000,
      durationKey: 'package.duration_1m',
      featureKeys: [
        'package.feature_router',
        'package.feature_unlimited',
        'package.feature_anywhere',
      ],
    ),
  ];

  void _openDetail(BuildContext context, String id) {
    context.pushNamed(
      RouteNames.packageDetail,
      pathParameters: {'id': id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return AppCurvedScaffold(
      title: Text('package.title'.tr()),
      showBack: false,
      body: ListView.separated(
        key: ValueKey('package-list-$locale'),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
        itemCount: _cards.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final data = _cards[index];
          return _PackageListCard(
            data: data,
            onOpenDetail: () => _openDetail(context, data.id),
          );
        },
      ),
    );
  }
}

enum _BadgeTone { none, popular, trending }

class _PackageListData {
  const _PackageListData({
    required this.id,
    required this.imagePath,
    required this.titleKey,
    required this.badgeKey,
    required this.badgeTone,
    required this.speedMbps,
    required this.pricePoints,
    required this.durationKey,
    required this.featureKeys,
  });

  final String id;
  final String imagePath;
  final String titleKey;
  final String? badgeKey;
  final _BadgeTone badgeTone;
  final String speedMbps;
  final int pricePoints;
  final String durationKey;
  final List<String> featureKeys;
}

class _PackageListCard extends StatelessWidget {
  const _PackageListCard({
    required this.data,
    required this.onOpenDetail,
  });

  final _PackageListData data;
  final VoidCallback onOpenDetail;

  static const _featureIcon = 'assets/images/packages/feature_check.png';
  static const _badgeYellow = Color(0xFFFFCC29);
  static const _badgeOrange = Color(0xFFFFB020);
  static const _optionFill = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    final hasBadge = data.badgeKey != null;

    return AppCard(
      elevated: false,
      bordered: false,
      borderRadius: BorderRadius.circular(10),
      padding: EdgeInsets.zero,
      onTap: onOpenDetail,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, hasBadge ? 14 : 10, 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 88,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        data.imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: AppColors.primaryLight,
                          child: Center(
                            child: Icon(
                              LucideIcons.image_off,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: hasBadge ? 72 : 0),
                          child: Text(
                            data.titleKey.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.english(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              height: 1.25,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoChip(
                                value: data.speedMbps,
                                unit: 'Mbps',
                                label: 'package.internet_speed'.tr(),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: _InfoChip(
                                value: NumberFormat('#,##0')
                                    .format(data.pricePoints),
                                unit: 'topup.pts'.tr(),
                                label:
                                    '${'package.price'.tr()} (${data.durationKey.tr()})',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0;
                                      i < data.featureKeys.length;
                                      i++) ...[
                                    if (i > 0) const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Image.asset(
                                          _featureIcon,
                                          width: 12,
                                          height: 12,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            LucideIcons.circle_check,
                                            size: 12,
                                            color: Color(0xFF499A13),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            data.featureKeys[i].tr(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTheme.english(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textMuted,
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _RegisterButton(onTap: onOpenDetail),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasBadge)
            Positioned(
              top: 0,
              right: 0,
              child: _CornerBadge(
                label: data.badgeKey!.tr(),
                background: data.badgeTone == _BadgeTone.trending
                    ? _badgeOrange
                    : _badgeYellow,
              ),
            ),
        ],
      ),
    );
  }
}

class _CornerBadge extends StatelessWidget {
  const _CornerBadge({
    required this.label,
    required this.background,
  });

  final String label;
  final Color background;

  static const _text = Color(0xFF3D2E00);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: AppTheme.english(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: _text,
          height: 1,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.value,
    required this.unit,
    required this.label,
  });

  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 6, 7, 6),
      decoration: BoxDecoration(
        color: _PackageListCard._optionFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTheme.english(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTheme.english(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.english(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(6);
    return Material(
      color: AppColors.primary,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.white.withValues(alpha: 0.18),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'home.buy_now'.tr(),
                style: AppTheme.english(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                LucideIcons.chevron_right,
                size: 12,
                color: AppColors.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
