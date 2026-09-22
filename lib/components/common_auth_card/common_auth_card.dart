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
    this.iconAsset,
    this.titleColor,
    this.child,
    this.secondaryAction,
  });

  final IconData? icon;
  /// Optional PNG (e.g. Flaticon) — preferred over [icon] when set.
  final String? iconAsset;
  final String? title;
  final Color? titleColor;
  final String description;
  final Widget? child;
  final Widget primaryAction;
  final Widget? secondaryAction;

  static const double _iconBox = 45;
  static const double _iconSize = 26;
  static const double _iconRadius = 10;
  static const double _letterSpacing = 0;

  @override
  Widget build(BuildContext context) {
    final hasIcon = iconAsset != null || icon != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasIcon) ...[
          Center(
            child: Container(
              width: _iconBox,
              height: _iconBox,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(_iconRadius),
              ),
              child: iconAsset != null
                  ? Image.asset(
                      iconAsset!,
                      width: _iconSize,
                      height: _iconSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    )
                  : Icon(
                      icon,
                      size: _iconSize,
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: titleColor ?? AppColors.textPrimary,
              letterSpacing: _letterSpacing,
            ),
          ),
          const SizedBox(height: AppStyle.spaceSm),
        ],
        Text(
          description,
          textAlign: TextAlign.center,
          style: AppTheme.english(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            letterSpacing: _letterSpacing,
            height: AppStyle.lineHeightBody,
          ),
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
      value: AppTheme.systemOverlayPrimary,
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
