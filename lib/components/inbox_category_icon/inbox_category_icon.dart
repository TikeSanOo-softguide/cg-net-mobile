import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../models/user_model/user_model.dart';
import '../quick_action_icon_chip/quick_action_icon_chip.dart';

/// Inbox category chip — primary PNG on [AppColors.primaryLight].
class InboxCategoryIcon extends StatelessWidget {
  const InboxCategoryIcon({
    super.key,
    required this.category,
    this.size = 38,
    this.iconSize = 22,
  });

  final InboxCategory category;
  final double size;
  final double iconSize;

  static const settingsAsset = 'assets/images/inbox/settings.png';
  static const promotionAsset = 'assets/images/inbox/promotion.png';
  static const messageAsset = 'assets/images/inbox/message.png';

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
    return QuickActionIconChip(
      asset: assetFor(category),
      background: AppColors.primaryLight,
      size: size,
      iconSize: iconSize,
    );
  }
}
