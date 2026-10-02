import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Soft chip + PNG — home top-up / history / account card.
class QuickActionIconChip extends StatelessWidget {
  const QuickActionIconChip({
    super.key,
    required this.asset,
    required this.background,
    this.size = 32,
    this.iconSize = 18,
    this.tint,
  });

  final String asset;
  final Color background;
  final double size;
  final double iconSize;
  final Color? tint;

  static const topUpAsset = 'assets/images/quick_actions/top_up.png';
  static const historyAsset = 'assets/images/quick_actions/history.png';
  static const paymentAsset = 'assets/images/quick_actions/payment.png';
  static const bindAsset = 'assets/images/quick_actions/bind.png';
  static const packageAsset = 'assets/images/quick_actions/package.png';
  static const billAsset = 'assets/images/quick_actions/pay_success.png';

  static const topUpSoft = AppColors.primaryLight;
  static const historySoft = Color(0xFFF3E8FF);
  static const paymentSoft = Color(0xFFFFF8DB);
  /// Light wash of [AppColors.success].
  static const bindSoft = Color(0xFFE3F2EA);
  /// Soft wash of package accent `#DA3D20`.
  static const packageSoft = Color(0xFFFBECE9);
  static const packageAccent = Color(0xFFDA3D20);
  /// Bill activity equity icon `#0E9F8A` on a light teal chip.
  static const billSoft = Color(0xFFE6F5F2);

  @override
  Widget build(BuildContext context) {
    Widget icon = Image.asset(
      asset,
      width: iconSize,
      height: iconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => Icon(
        Icons.broken_image_outlined,
        size: iconSize,
        color: tint ?? AppColors.primary,
      ),
    );

    if (tint != null) {
      icon = ColorFiltered(
        colorFilter: ColorFilter.mode(tint!, BlendMode.srcIn),
        child: icon,
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppStyle.borderRadiusInput,
      ),
      child: icon,
    );
  }
}
