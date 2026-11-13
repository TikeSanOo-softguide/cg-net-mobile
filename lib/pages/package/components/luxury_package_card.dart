import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Pricing card: plan name, colored price + /Month, 4 features, wave + BUY NOW.
class LuxuryPackageCard extends StatelessWidget {
  const LuxuryPackageCard({
    super.key,
    this.title = '',
    required this.priceLabel,
    required this.periodLabel,
    required this.speedLabel,
    required this.onBuy,
    this.onTap,
    this.popular = false,
    this.footer,
    this.productId = '',
    this.lineLabel = '',
    this.accentIndex = 0,
    this.compact = false,
  });

  static const List<Color> accents = [
    Color(0xFF1FBF5A),
    Color(0xFFF43D7A),
    Color(0xFF8B4DFF),
  ];

  static const _planKeys = [
    'package.plan_basic',
    'package.plan_standard',
    'package.plan_premium',
  ];

  static Color accentAt(int index) => accents[index % accents.length];

  static String planName(int index) => _planKeys[index % 3].tr();

  static String monthStyle({int? months, bool isDay = false}) {
    if (isDay) return 'package.price_day'.tr();
    if (months != null && months > 1) {
      return 'package.price_months'.tr(namedArgs: {'count': '$months'});
    }
    return 'package.price_month'.tr();
  }

  final String title;
  final String priceLabel;
  final String periodLabel;
  final String speedLabel;
  final VoidCallback onBuy;
  final VoidCallback? onTap;
  final bool popular;
  final Widget? footer;
  final String productId;
  final String lineLabel;
  final int accentIndex;
  final bool compact;

  String get _name {
    if (title.trim().isNotEmpty) return title.trim();
    return planName(accentIndex);
  }

  List<String> get _facts {
    return [
      'package.feature_unlimited'.tr(),
      'package.feature_speed'.tr(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final accent = accentAt(accentIndex);
    final radius = 8.0;
    final body = _CardBody(
      compact: compact,
      accent: accent,
      name: _name,
      amount: priceLabel.trim(),
      monthLabel: periodLabel.trim(),
      speedLabel: speedLabel.trim(),
      facts: _facts,
      onBuy: onBuy,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Material(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap ?? onBuy,
          splashColor: accent.withValues(alpha: 0.08),
          highlightColor: accent.withValues(alpha: 0.04),
          child: Column(
            mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (compact) Expanded(child: body) else body,
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.compact,
    required this.accent,
    required this.name,
    required this.amount,
    required this.monthLabel,
    required this.speedLabel,
    required this.facts,
    required this.onBuy,
  });

  final bool compact;
  final Color accent;
  final String name;
  final String amount;
  final String monthLabel;
  final String speedLabel;
  final List<String> facts;
  final VoidCallback onBuy;

  ({String value, String unit}) get _speed {
    final text = speedLabel.trim();
    if (text.toLowerCase().endsWith('mbps')) {
      return (
        value: text.substring(0, text.length - 4).trim(),
        unit: 'Mbps',
      );
    }
    return (value: text, unit: 'Mbps');
  }

  @override
  Widget build(BuildContext context) {
    final speed = _speed;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _CornerWavePainter(color: accent),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24,
            compact ? 24 : 30,
            compact ? 14 : 24,
            compact ? 36 : 48,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.english(
                  fontSize: compact ? 13 : 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A28),
                  height: 1.15,
                  letterSpacing: 0.2,
                ),
              ),
              SizedBox(height: compact ? 6 : 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.english(
                        fontSize: compact ? 36 : 46,
                        fontWeight: FontWeight.w800,
                        color: accent,
                        height: 1,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  if (monthLabel.isNotEmpty)
                    Text(
                      monthLabel.startsWith('/')
                          ? monthLabel
                          : '/$monthLabel',
                      style: AppTheme.english(
                        fontSize: compact ? 13 : 16,
                        fontWeight: FontWeight.w600,
                        color: accent,
                        height: 1,
                      ),
                    ),
                ],
              ),
              if (speed.value.isNotEmpty) ...[
                SizedBox(height: compact ? 18 : 22),
                Center(
                  child: _SpeedBadge(
                    compact: compact,
                    accent: accent,
                    value: speed.value,
                    unit: speed.unit,
                  ),
                ),
              ],
              if (facts.isNotEmpty) ...[
              SizedBox(height: compact ? 12 : 16),
              for (var i = 0; i < facts.length; i++) ...[
                if (i > 0) SizedBox(height: compact ? 4 : 8),
                Text(
                  facts[i],
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.english(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                    height: 1.2,
                  ),
                ),
              ],
              ],
            ],
          ),
        ),
        Positioned(
          right: compact ? 10 : 16,
          bottom: compact ? 10 : 14,
          child: GestureDetector(
            onTap: onBuy,
            child: Text(
              'home.buy_now'.tr().toUpperCase(),
              style: AppTheme.english(
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.7,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge({
    required this.compact,
    required this.accent,
    required this.value,
    required this.unit,
  });

  final bool compact;
  final Color accent;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 6 : 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: AppTheme.english(
                fontSize: compact ? 20 : 26,
                fontWeight: FontWeight.w800,
                color: accent,
                height: 1,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: AppTheme.english(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w700,
                color: accent.withValues(alpha: 0.75),
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CornerWavePainter extends CustomPainter {
  const _CornerWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height)
      ..arcToPoint(
        Offset(size.width, size.height * 0.48),
        radius: Radius.elliptical(size.width * 0.92, size.height * 0.58),
        clockwise: false,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topRight,
          colors: [
            color,
            Color.lerp(color, Colors.white, 0.12) ?? color,
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _CornerWavePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
