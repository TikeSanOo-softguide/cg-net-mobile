import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../components/page_skeletons/home_skeletons.dart';
import '../../../../core/router/route_names/route_names.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';
import '../../../../models/package_model/package_model.dart';
import '../../../package/components/luxury_package_card.dart';
import '../../../package/package_list/package_list_controller.dart';

/// Special Packages For You — wide, short plan cards in a horizontal row.
class HomeCgPackageSection extends StatelessWidget {
  const HomeCgPackageSection({super.key});

  @override
  Widget build(BuildContext context) => const _HomePackageStrip();
}

class _HomePackageStrip extends ConsumerWidget {
  const _HomePackageStrip();

  static const _cardHeight = 152.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(packageListControllerProvider);
    final items = state.packages.take(3).toList();
    final showSkeleton =
        items.isEmpty && state.status == PackageListStatus.loading;
    if (!showSkeleton && items.isEmpty) return const SizedBox.shrink();

    final cardWidth = (MediaQuery.sizeOf(context).width * 0.72).clamp(
      240.0,
      320.0,
    );

    return Padding(
      padding: AppStyle.pagePaddingH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'home.cg_package'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.goNamed(RouteNames.packageList),
                borderRadius: BorderRadius.circular(8),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    'home.see_all'.tr(),
                    style: AppTheme.caption(
                      color: AppColors.primary,
                      weight: FontWeight.w500,
                    ).copyWith(
                      fontSize: 11,
                      height: AppTheme.lineHeightMyanmarSafe,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: showSkeleton
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: showSkeleton ? 2 : items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: cardWidth,
                  child: showSkeleton
                      ? const HomePackageCardSkeleton()
                      : _WidePlanCard(model: items[index], index: index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WidePlanCard extends StatelessWidget {
  const _WidePlanCard({required this.model, required this.index});

  final PackageModel model;
  final int index;

  @override
  Widget build(BuildContext context) {
    final accent = LuxuryPackageCard.accentAt(index);
    final speed = model.speed.trim();
    final speedText =
        speed.toLowerCase().contains('mbps') ? speed : '$speed Mbps';
    final speedParts = speedText.split(RegExp(r'\s+'));
    final speedValue = speedParts.isEmpty ? '' : speedParts.first;
    final speedUnit =
        speedParts.length > 1 ? speedParts.sublist(1).join(' ') : '';
    final cycle = [
      if (model.termMonths != null) '${model.termMonths}',
      model.billingCycle.trim(),
    ].join();
    final period =
        cycle.isEmpty ? '' : (cycle.startsWith('/') ? cycle : '/$cycle');
    final line = model.currency.trim();
    final productLine = line.isNotEmpty ? line : model.name.trim();
    void open() {
      context.pushNamed(
        RouteNames.packageDetail,
        pathParameters: {'id': model.id},
      );
    }

    return Material(
      color: AppColors.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: open,
        child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _HomeWavePainter(color: accent),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 14, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      child: Text(
                                        productLine,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.english(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: accent,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${model.price}',
                                maxLines: 1,
                                style: AppTheme.english(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                  height: 1,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (period.isNotEmpty)
                                Text(
                                  period,
                                  maxLines: 1,
                                  style: AppTheme.english(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: accent,
                                    height: 1,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 72, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (speedValue.isNotEmpty)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Flexible(
                                  child: Text(
                                    speedValue,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.english(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: accent,
                                      height: 1,
                                    ),
                                  ),
                                ),
                                if (speedUnit.isNotEmpty) ...[
                                  const SizedBox(width: 5),
                                  Text(
                                    speedUnit,
                                    style: AppTheme.english(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: accent,
                                      height: 1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: speedValue.isNotEmpty ? 15 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var i = 0; i < 2; i++) ...[
                                  if (i > 0) const SizedBox(height: 6),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          i == 0
                                              ? 'package.feature_unlimited'.tr()
                                              : 'package.feature_speed'.tr(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.english(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF6B7280),
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: GestureDetector(
                  onTap: open,
                  child: Text(
                    'home.buy_now'.tr().toUpperCase(),
                    style: AppTheme.english(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.7,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}

class _HomeWavePainter extends CustomPainter {
  const _HomeWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.38, size.height)
      ..arcToPoint(
        Offset(size.width, size.height * 0.32),
        radius: Radius.elliptical(size.width * 0.72, size.height * 0.82),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HomeWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
