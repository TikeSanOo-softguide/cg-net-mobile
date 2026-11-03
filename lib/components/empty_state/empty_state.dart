import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = LucideIcons.inbox,
    this.iconAsset,
    this.iconBackground = AppColors.primaryLight,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? iconAsset;
  final Color iconBackground;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyle.spaceXxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconAsset != null)
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: AppStyle.borderRadiusLg,
                ),
                child: Image.asset(
                  iconAsset!,
                  width: 40,
                  height: 40,
                  filterQuality: FilterQuality.high,
                ),
              )
            else
              Icon(icon, size: 40, color: AppColors.error),
            const SizedBox(height: AppStyle.spaceLg),
            Text(
              title,
              style: AppTheme.cardTitle(color: AppColors.primary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyle.spaceSm),
            Text(
              message,
              style: AppTheme.bodySecondary(),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppStyle.spaceLg),
              _RetryButton(label: actionLabel!, onPressed: onAction!),
            ],
          ],
        ),
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.refresh_cw,
                size: 12,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTheme.caption(
                  color: AppColors.onPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
