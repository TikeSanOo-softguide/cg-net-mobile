import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../models/user_model/user_model.dart';
import '../quick_action_icon_chip/quick_action_icon_chip.dart';

/// Inbox category chip — primary PNG on [AppColors.primaryLight].
/// Failure messages use dialog failure icon on soft red chip.
class InboxCategoryIcon extends StatelessWidget {
  const InboxCategoryIcon({
    super.key,
    required this.category,
    this.size = 38,
    this.iconSize = 22,
    this.isFailure = false,
  });

  final InboxCategory category;
  final double size;
  final double iconSize;
  final bool isFailure;

  static const settingsAsset = 'assets/images/inbox/settings.png';
  static const promotionAsset = 'assets/images/inbox/promotion.png';
  static const messageAsset = 'assets/images/inbox/message.png';
  static const failureAsset = 'assets/images/dialogs/failure.png';

  /// Soft wash of fail red `#D90000`.
  static const failureSoft = Color(0xFFFCE6E6);
  static const failureColor = Color(0xFFD90000);

  static String assetFor(InboxCategory category) {
    switch (category) {
      case InboxCategory.announcement:
        return messageAsset;
      case InboxCategory.system:
        return settingsAsset;
      case InboxCategory.promotion:
        return promotionAsset;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isFailure) {
      return QuickActionIconChip(
        asset: failureAsset,
        background: failureSoft,
        size: size,
        iconSize: iconSize,
      );
    }
    return QuickActionIconChip(
      asset: assetFor(category),
      background: AppColors.primaryLight,
      size: size,
      iconSize: iconSize,
    );
  }
}
