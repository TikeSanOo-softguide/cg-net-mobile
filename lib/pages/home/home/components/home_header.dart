import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../components/app_logo/app_logo.dart';
import '../../../../core/theme/app_colors/app_colors.dart';
import '../../../../core/theme/app_style/app_style.dart';
import '../../../../core/theme/app_theme/app_theme.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({
    super.key,
    required this.accountNumber,
    required this.balanceAmount,
  });

  final String accountNumber;
  final String balanceAmount;

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  bool _balanceVisible = false;

  String get _maskedAmount => '********';

  String get _visibleAmount {
    final raw = widget.balanceAmount.replaceAll(',', '');
    final value = double.tryParse(raw);
    if (value == null) return widget.balanceAmount;
    return NumberFormat('#,##0').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    // Responsive overlay sizes — bigger, more visible; no small third circle.
    final topOrb = (w * 0.48).clamp(160.0, 210.0);
    final bottomOrb = (w * 0.32).clamp(110.0, 150.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Rounded primary fill (clips only the blue surface).
          Positioned.fill(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              child: const ColoredBox(color: AppColors.primary),
            ),
          ),
          // Top-right orb — kept off Bind Now (far top-right corner).
          Positioned(
            top: -(topOrb * 0.42),
            right: -(topOrb * 0.38),
            child: Container(
              width: topOrb,
              height: topOrb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                  width: 0.6,
                ),
              ),
            ),
          ),
          // Bottom-left orb — peeks under header curve / Top-up card.
          Positioned(
            bottom: -(bottomOrb * 0.28),
            left: -(bottomOrb * 0.32),
            child: Container(
              width: bottomOrb,
              height: bottomOrb,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.20),
                  width: 0.6,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 52),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Row(
                    children: [
                      AppLogo(
                        width: 60,
                        height: 50,
                        padding: 0,
                        borderRadius: 0,
                        backgroundColor: Colors.transparent,
                        showShadow: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'home.account_number'.tr(),
                              style: AppTheme.english(
                                color: AppColors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.accountNumber,
                              style: AppTheme.english(
                                color: AppColors.onPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(8),
                          overlayColor: WidgetStateProperty.all(
                            Colors.white.withValues(alpha: 0.08),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.link,
                                  color: AppColors.onPrimary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'home.bind_now'.tr(),
                                  style: AppTheme.english(
                                    color: AppColors.onPrimary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(
                                () => _balanceVisible = !_balanceVisible,
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            overlayColor: WidgetStateProperty.all(
                              Colors.white.withValues(alpha: 0.08),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LucideIcons.wallet,
                                    color: AppColors.onPrimary,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'home.balance_label'.tr(),
                                    style: AppTheme.english(
                                      color: AppColors.onPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _balanceVisible
                                        ? LucideIcons.eye
                                        : LucideIcons.eye_off,
                                    color: AppColors.onPrimary,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppStyle.spaceMd),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _balanceVisible ? _visibleAmount : _maskedAmount,
                              textAlign: TextAlign.center,
                              style: AppTheme.english(
                                color: AppColors.onPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: _balanceVisible ? 0.2 : 1.5,
                                height: AppStyle.lineHeightTitle,
                              ),
                            ),
                            if (_balanceVisible) ...[
                              const SizedBox(width: AppStyle.spaceXs),
                              Text(
                                'Pts',
                                style: AppTheme.english(
                                  color: AppColors.onPrimary,
                                  fontSize: AppStyle.fontBodyLg,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
