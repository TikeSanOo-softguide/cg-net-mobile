import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/app_card/app_card.dart';
import '../../../components/app_curved_scaffold/app_curved_scaffold.dart';
import '../../../components/empty_state/empty_state.dart';
import '../../../components/shimmer_loading/shimmer_loading.dart';
import '../../../core/network/api_error_text.dart';
import '../../../core/network/network_recovery_controller.dart';
import '../../../core/network/offline_navigation.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';
import '../../../models/package_model/package_model.dart';
import 'package_list_controller.dart';

/// Packages tab — compact horizontal list cards (reference design).
class PackageListPage extends ConsumerWidget {
  const PackageListPage({super.key});

  void _openDetail(BuildContext context, String id) {
    context.pushNamed(
      RouteNames.packageDetail,
      pathParameters: {'id': id},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = context.locale.languageCode;
    final state = ref.watch(packageListControllerProvider);

    return AppCurvedScaffold(
      title: Text('package.title'.tr()),
      showBack: false,
      body: switch (state.status) {
        PackageListStatus.loading => const ShimmerLoading(
            itemCount: 6,
            itemHeight: 168,
          ),
        PackageListStatus.empty => EmptyState(
            title: 'package.empty_title'.tr(),
            message: 'package.empty_body'.tr(),
            actionLabel: 'common.retry'.tr(),
            onAction: () =>
                ref.read(packageListControllerProvider.notifier).load(),
          ),
        PackageListStatus.error => EmptyState(
            title: 'common.error'.tr(),
            message: apiMessageText(state.errorMessage),
            actionLabel: 'common.retry'.tr(),
            onAction: () async {
              const recoveryKey = 'package-list-load';
              if (state.errorMessage == 'api.offline') {
                ref.read(networkRecoveryControllerProvider).enqueue(
                      recoveryKey,
                      () async => ref
                          .read(packageListControllerProvider.notifier)
                          .load(),
                    );
                final shouldRetry = await openNoInternetPage(context);
                if (shouldRetry == true && context.mounted) {
                  ref
                      .read(networkRecoveryControllerProvider)
                      .clear(recoveryKey);
                  ref.read(packageListControllerProvider.notifier).load();
                }
                return;
              }
              ref.read(packageListControllerProvider.notifier).load();
            },
          ),
        PackageListStatus.data => ListView.separated(
            key: ValueKey('package-list-$locale'),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
            itemCount: state.packages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = _PackageListData.fromModel(
                state.packages[index],
                localeCode: locale,
              );
              return _PackageListCard(
                data: data,
                onOpenDetail: () => _openDetail(context, data.id),
              );
            },
          ),
      },
    );
  }
}

enum _BadgeTone { none, popular, trending }

class _PackageListData {
  const _PackageListData({
    required this.id,
    required this.imagePath,
    required this.titleKey,
    this.title,
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
  final String? title;
  final String? badgeKey;
  final _BadgeTone badgeTone;
  final String speedMbps;
  final int pricePoints;
  final String durationKey;
  final List<String> featureKeys;

  factory _PackageListData.fromModel(
    PackageModel model, {
    required String localeCode,
  }) {
    final months = model.termMonths;
    final speed = model.speed.replaceAll(RegExp(r'[^0-9]'), '');
    final durationKey = switch (months) {
      1 => 'package.duration_1m',
      3 => 'package.duration_3m',
      6 => 'package.duration_6m',
      12 => 'package.duration_12m',
      _ => 'package.duration_1m',
    };
    return _PackageListData(
      id: model.id,
      imagePath: _imageFor(model),
      titleKey: '',
      badgeKey: model.recommended ? 'package.badge_popular' : null,
      badgeTone: model.recommended ? _BadgeTone.popular : _BadgeTone.none,
      speedMbps: speed.isEmpty ? '0' : speed,
      pricePoints: model.price.toInt(),
      durationKey: durationKey,
      featureKeys: const [
        'package.feature_speed',
        'package.feature_unlimited',
        'package.feature_term',
      ],
      title: model.localizedName?[localeCode] ??
          model.localizedName?['en'] ??
          model.name,
    );
  }

  static String _imageFor(PackageModel model) {
    final fromApi = model.imageUrl;
    if (fromApi != null && fromApi.trim().isNotEmpty) {
      return fromApi;
    }
    final months = model.termMonths;
    return switch (months) {
      3 => 'assets/images/packages/package_3m.png',
      6 => 'assets/images/packages/package_6m.png',
      12 => 'assets/images/packages/package_1y.png',
      _ => 'assets/images/packages/package_1m.png',
    };
  }
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

  Widget _buildCardImage(String imagePath) {
    const fallback = ColoredBox(
      color: AppColors.primaryLight,
      child: Center(
        child: Icon(
          LucideIcons.image_off,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => fallback,
    );
  }

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
                      child: _buildCardImage(data.imagePath),
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
                            data.title ?? data.titleKey.tr(),
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
                                            color: Color(0xFF3D7A12),
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
                                              height: AppTheme.lineHeightMyanmarSafe,
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
          height: AppTheme.lineHeightMyanmarSafe,
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
                    height: AppTheme.lineHeightMyanmarSafe,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTheme.english(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    height: AppTheme.lineHeightMyanmarSafe,
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
              height: AppTheme.lineHeightMyanmarSafe,
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
                  height: AppTheme.lineHeightMyanmarSafe,
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
