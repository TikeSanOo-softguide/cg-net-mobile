import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../app_circle_icon_button/app_circle_icon_button.dart';
import '../../core/theme/app_colors/app_colors.dart';
import '../../core/theme/app_style/app_style.dart';
import '../../core/theme/app_theme/app_theme.dart';

/// Shared auth content — icon, title, description, fields, CTA.
class CommonAuthCard extends StatelessWidget {
  const CommonAuthCard({
    super.key,
    required this.description,
    required this.primaryAction,
    this.title,
    this.icon,
    this.child,
    this.secondaryAction,
  });

  final IconData? icon;
  final String? title;
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
        if (icon != null) ...[
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: AppStyle.spaceLg),
        ],
        if (title != null && title!.trim().isNotEmpty) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: AppTheme.english(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppStyle.spaceSm),
        ],
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTheme.bodySecondary(),
        ),
        if (child != null) ...[
          const SizedBox(height: AppStyle.spaceXl),
          child!,
        ],
        const SizedBox(height: AppStyle.spaceXl),
        primaryAction,
        if (secondaryAction != null) ...[
          const SizedBox(height: AppStyle.spaceSm),
          secondaryAction!,
        ],
      ],
    );
  }
}

/// Shared auth shell — primary header + curved white sheet (no CG-NET label).
class AuthBackgroundScaffold extends StatelessWidget {
  const AuthBackgroundScaffold({
    super.key,
    required this.card,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.header,
    this.headerTitle,
    this.headerTitleGap,
    this.headerBodyTopGap,
    this.topBarTitle,
    this.compactTop = false,
    this.headerTopPadding,
    this.headerBottomPadding,
    this.sheetRadius,
  });

  final Widget card;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Optional custom header under the top bar (e.g. logo on login).
  final Widget? header;
  final String? headerTitle;

  /// Space between [header] and [headerTitle].
  final double? headerTitleGap;

  /// Space between top bar row and [header] / title block.
  /// Larger values push logo + title toward the bottom of the blue area.
  final double? headerBodyTopGap;

  /// Centered title inside the compact top bar (OTP / Create account).
  final String? topBarTitle;

  /// Tighter blue header (less top/bottom padding).
  final bool compactTop;

  /// Override top padding above the blue header content.
  final double? headerTopPadding;

  /// Override bottom padding under the blue header content.
  final double? headerBottomPadding;

  /// White sheet top radius. Defaults to [AppStyle.radiusCurve] (24).
  final double? sheetRadius;

  @override
  Widget build(BuildContext context) {
    final hasHeaderContent = header != null || headerTitle != null;
    final useTopBarTitle =
        topBarTitle != null && topBarTitle!.trim().isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppStyle.spaceLg,
                  headerTopPadding ??
                      (compactTop ? AppStyle.spaceSm : AppStyle.spaceXs),
                  AppStyle.spaceLg,
                  headerBottomPadding ??
                      (useTopBarTitle
                          ? AppStyle.spaceMd
                          : (hasHeaderContent
                              ? (compactTop
                                  ? AppStyle.spaceMd
                                  : AppStyle.spaceLg)
                              : AppStyle.spaceMd)),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: AppStyle.topBarHeight,
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
                          Expanded(
                            child: useTopBarTitle
                                ? Text(
                                    topBarTitle!,
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.topBarTitle(),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          trailing ??
                              const SizedBox(width: AppStyle.circleButtonSize),
                        ],
                      ),
                    ),
                    if (header != null) ...[
                      SizedBox(
                        height: headerBodyTopGap ??
                            (compactTop ? AppStyle.spaceXs : AppStyle.spaceSm),
                      ),
                      header!,
                    ],
                    if (headerTitle != null) ...[
                      SizedBox(
                        height: headerTitleGap ??
                            (header != null
                                ? AppStyle.spaceXs
                                : AppStyle.spaceSm),
                      ),
                      Text(
                        headerTitle!,
                        textAlign: TextAlign.center,
                        style: AppTheme.topBarTitle(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(
                      sheetRadius ?? AppStyle.radiusCurve,
                    ),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
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
