import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Segmented tabs — taller track, horizontally sliding primary pill.
class AppGlassTabBar extends StatelessWidget {
  const AppGlassTabBar({
    super.key,
    required this.controller,
    required this.labels,
  });

  final TabController controller;
  final List<String> labels;

  static const double _height = 44;
  static const double _pad = 4;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.languageCode;

    return Container(
      key: ValueKey('glass-tabs-$locale'),
      height: _height,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppStyle.borderRadiusSm,
        border: Border.all(color: AppColors.borderLight, width: 0.5),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / labels.length;
          final pillHeight = constraints.maxHeight;

          return AnimatedBuilder(
            animation: controller.animation ?? controller,
            builder: (context, _) {
              final value =
                  controller.animation?.value ?? controller.index.toDouble();

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Horizontally sliding selected pill (follows swipe + tap).
                  Positioned(
                    left: value * tabWidth,
                    top: 0,
                    width: tabWidth,
                    height: pillHeight,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        Expanded(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                if (controller.index == i) return;
                                controller.animateTo(
                                  i,
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutCubic,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              child: SizedBox(
                                height: pillHeight,
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        labels[i].tr(),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: AppTheme.english(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color.lerp(
                                            AppColors.textMuted,
                                            AppColors.onPrimary,
                                            _selectionStrength(value, i),
                                          ),
                                          height: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 1 when pill is fully on [index], 0 when far away — smooth color blend.
  static double _selectionStrength(double value, int index) {
    final distance = (value - index).abs();
    if (distance >= 1) return 0;
    return 1 - distance;
  }
}
