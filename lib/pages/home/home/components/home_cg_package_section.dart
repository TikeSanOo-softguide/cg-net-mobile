import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  static const _cardHeight = 146.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packages = ref.watch(packageListControllerProvider).packages;
    final items = packages.take(3).toList();
    if (items.isEmpty) return const SizedBox.shrink();

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
              GestureDetector(
                onTap: () => context.goNamed(RouteNames.packageList),
                child: Text(
                  'common.see_more'.tr(),
                  style: AppTheme.english(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    height: 1.2,
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
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                return SizedBox(
                  width: cardWidth,
                  child: _WidePlanCard(model: items[index], index: index),
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
    final period = cycle.isEmpty
        ? ''
        : (cycle.startsWith('/') ? cycle : '/$cycle');
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
      child: InkWell(
        onTap: open,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
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
                padding: const EdgeInsets.only(bottom: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ColoredBox(
                            color: accent,
                            child: const SizedBox(width: 5),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          LuxuryPackageCard.planName(index),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppTheme.english(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            height: 1.15,
                                          ),
                                        ),
                                        if (speedValue.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: accent.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.baseline,
                                                textBaseline:
                                                    TextBaseline.alphabetic,
                                                children: [
                                                  Text(
                                                    speedValue,
                                                    style: AppTheme.english(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: accent,
                                                      height: 1,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  if (speedUnit.isNotEmpty) ...[
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      speedUnit,
                                                      style: AppTheme.english(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: accent,
                                                        height: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${model.price}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTheme.english(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w800,
                                          color: accent,
                                          height: 1,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      if (period.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          period,
                                          maxLines: 1,
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
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(19, 4, 72, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final label in [
                            'package.feature_unlimited'.tr(),
                            'package.feature_speed'.tr(),
                          ]) ...[
                            const SizedBox(height: 4),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.english(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF6B7280),
                                height: 1.2,
                              ),
                            ),
                          ],
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
      ..moveTo(size.width * 0.46, size.height)
      ..arcToPoint(
        Offset(size.width, size.height * 0.42),
        radius: Radius.elliptical(size.width * 0.62, size.height * 0.7),
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
