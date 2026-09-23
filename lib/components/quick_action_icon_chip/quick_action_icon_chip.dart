import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Soft chip + PNG — same look as home top-up / transfer / history card.
class QuickActionIconChip extends StatelessWidget {
  const QuickActionIconChip({
    super.key,
    required this.asset,
    required this.background,
    this.size = 32,
    this.iconSize = 18,
  });

  final String asset;
  final Color background;
  final double size;
  final double iconSize;

  static const topUpAsset = 'assets/images/quick_actions/top_up.png';
  static const transferAsset = 'assets/images/quick_actions/transfer.png';
  static const historyAsset = 'assets/images/quick_actions/history.png';
  static const paymentAsset = 'assets/images/quick_actions/payment.png';

  static const topUpSoft = Color(0xFFE8E8FC);
  static const transferSoft = Color(0xFFE6F7F4);
  static const historySoft = Color(0xFFF3E8FF);
  static const paymentSoft = Color(0xFFFFF8DB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppStyle.borderRadiusInput,
      ),
      child: Image.asset(
        asset,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, __, ___) => Icon(
          Icons.broken_image_outlined,
          size: iconSize,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
