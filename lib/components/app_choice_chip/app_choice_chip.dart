import 'package:flutter/material.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Equal-width wrap used by plan option chips.
class AppChoiceGrid extends StatelessWidget {
  const AppChoiceGrid({
    super.key,
    required this.children,
    this.columns = 2,
  });

  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppStyle.spaceSm;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Compact selectable chip used for service type, speed, and billing period.
class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;
    final labelStyle = AppTheme.english(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.15,
      color: color,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: double.infinity,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.borderLight,
              width: 0.5,
            ),
          ),
          child: icon == null
              ? Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: labelStyle,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: labelStyle,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
