import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../components/app_circle_icon_button/app_circle_icon_button.dart';
import '../../../core/theme/app_colors/app_colors.dart';
import '../../../core/theme/app_style/app_style.dart';
import '../../../core/theme/app_theme/app_theme.dart';

/// Shared auth content (no floating card) — icon, title, description, fields, CTA.
class CommonAuthCard extends StatelessWidget {
  const CommonAuthCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.primaryAction,
    this.child,
    this.secondaryAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? child;
  final Widget primaryAction;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppStyle.iconSizeLg,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: AppStyle.spaceLg),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle(),
        ),
        const SizedBox(height: AppStyle.spaceSm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTheme.bodySecondary(),
        ),
        if (child != null) ...[
          const SizedBox(height: AppStyle.spaceXxl),
          child!,
        ],
        const SizedBox(height: AppStyle.spaceXxl),
        primaryAction,
        if (secondaryAction != null) ...[
          const SizedBox(height: AppStyle.spaceXs),
          secondaryAction!,
        ],
      ],
    );
  }
}

/// Auth background: compact primary top + curved white content sheet.
class AuthBackgroundScaffold extends StatelessWidget {
  const AuthBackgroundScaffold({
    super.key,
    required this.card,
    this.showBack = false,
    this.onBack,
    this.trailing,
  });

  final Widget card;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            // Compact primary top header
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppStyle.spaceLg,
                  AppStyle.spaceXs,
                  AppStyle.spaceLg,
                  AppStyle.spaceXl,
                ),
                child: SizedBox(
                  height: AppStyle.circleButtonSize,
                  child: Row(
                    children: [
                      if (showBack)
                        AppCircleIconButton(
                          icon: LucideIcons.chevron_left,
                          onPressed: onBack ??
                              () => Navigator.of(context).maybePop(),
                        )
                      else
                        const SizedBox(width: AppStyle.circleButtonSize),
                      const Spacer(),
                      Text(
                        'CG-NET',
                        style: AppTheme.topBarTitle(),
                      ),
                      const Spacer(),
                      trailing ??
                          const SizedBox(width: AppStyle.circleButtonSize),
                    ],
                  ),
                ),
              ),
            ),
            // White curved content fills the rest
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppStyle.radiusCurve),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: AppStyle.pagePadding,
                  child: card,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

