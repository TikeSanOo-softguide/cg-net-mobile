import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

/// Small promotion alert between services and special offers.
/// Two lines take turns sliding upward.
class HomePromoAlert extends StatefulWidget {
  const HomePromoAlert({super.key});

  @override
  State<HomePromoAlert> createState() => _HomePromoAlertState();
}

class _HomePromoAlertState extends State<HomePromoAlert>
    with SingleTickerProviderStateMixin {
  static const _lineHeight = 26.0;

  late final AnimationController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() => _index = (_index + 1) % 2);
        _controller.forward(from: 0);
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = [
      'home.promo_alert_primary'.tr(),
      'home.promo_alert_secondary'.tr(),
    ];
    final slide = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.74, 1, curve: Curves.easeInOut),
    );

    return Padding(
      padding: AppStyle.pagePaddingH,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColoredBox(
          color: AppColors.primaryLight,
          child: IntrinsicHeight(
            child: Row(
              children: [
                const ColoredBox(
                  color: AppColors.primary,
                  child: SizedBox(width: 5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/images/inbox/promotion.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: _lineHeight,
                            child: ClipRect(
                              child: AnimatedBuilder(
                                animation: slide,
                                builder: (context, _) {
                                  final t = slide.value;
                                  final current = lines[_index];
                                  final next =
                                      lines[(_index + 1) % lines.length];
                                  return Stack(
                                    children: [
                                      Opacity(
                                        opacity: 1 - t,
                                        child: Transform.translate(
                                          offset: Offset(0, -t * _lineHeight),
                                          child: _line(current),
                                        ),
                                      ),
                                      Opacity(
                                        opacity: t,
                                        child: Transform.translate(
                                          offset: Offset(0, (1 - t) * _lineHeight),
                                          child: _line(next),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _line(String text) {
    return SizedBox(
      height: _lineHeight,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          softWrap: false,
          style: AppTheme.english(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
            height: AppTheme.lineHeightMyanmarSafe,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
