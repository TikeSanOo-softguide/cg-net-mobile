import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';

/// Reusable Floating Action Button for adding new requests/complaints across services.
class AppAddFloatingActionButton extends StatelessWidget {
  const AppAddFloatingActionButton({
    super.key,
    required this.onPressed,
    this.heroTag,
    this.tooltip,
    this.backgroundColor = AppColors.primary,
    this.iconColor = Colors.white,
    this.icon = LucideIcons.plus,
    this.iconSize = 22.0,
    this.elevation = 4.0,
    this.mini = true,
  });

  final VoidCallback onPressed;
  final Object? heroTag;
  final String? tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final double iconSize;
  final double elevation;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      tooltip: tooltip,
      onPressed: onPressed,
      backgroundColor: backgroundColor,
      elevation: elevation,
      mini: mini,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyle.borderRadiusButton,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: iconSize,
      ),
    );
  }
}
