import 'package:flutter/material.dart';

import '../app_colors/app_colors.dart';

/// Shared layout + type tokens for CG-NET UI.
class AppStyle {
  AppStyle._();

  // —— Spacing (4px scale) ——
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double spaceXxl = 24;
  static const double spaceXxxl = 32;

  static const EdgeInsets pagePadding = EdgeInsets.all(spaceXxl);
  static const EdgeInsets pagePaddingH = EdgeInsets.symmetric(horizontal: spaceLg);
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceLg);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: spaceXl);

  // —— Radius ——
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusNav = 24;
  static const double radiusCurve = 28;
  static const double radiusInput = 8;
  static const double radiusButton = 10;

  static BorderRadius get borderRadiusSm => BorderRadius.circular(radiusSm);
  static BorderRadius get borderRadiusMd => BorderRadius.circular(radiusMd);
  static BorderRadius get borderRadiusLg => BorderRadius.circular(radiusLg);
  static BorderRadius get borderRadiusXl => BorderRadius.circular(radiusXl);
  static BorderRadius get borderRadiusInput =>
      BorderRadius.circular(radiusInput);
  static BorderRadius get borderRadiusButton =>
      BorderRadius.circular(radiusButton);
  static BorderRadius get borderRadiusNav =>
      const BorderRadius.vertical(bottom: Radius.circular(radiusNav));
  static BorderRadius get borderRadiusCurve =>
      const BorderRadius.vertical(top: Radius.circular(radiusCurve));

  // —— Control sizes ——
  static const double controlHeight = 46;
  static const double iconSize = 20;
  static const double iconSizeSm = 18;
  static const double iconSizeLg = 22;
  static const double iconBox = 40;
  static const double circleButtonSize = 36;
  static const double topBarHeight = 56;
  static const double bottomNavHeight = 64;
  static const double bottomNavIconSize = 22;
  static const double bottomNavLabelSize = 11;
  static const double bottomNavIconGap = 4;

  // —— Typography sizes ——
  static const double fontHero = 28;
  static const double fontPageTitle = 22;
  static const double fontTopBarTitle = 18;
  static const double fontSectionTitle = 15;
  static const double fontCardTitle = 15;
  static const double fontBody = 14;
  static const double fontBodyLg = 15;
  static const double fontSecondary = 13;
  static const double fontCaption = 11;
  static const double fontCaptionSm = 11;
  static const double fontButton = 14;
  static const double fontAmount = 28;

  /// Comfortable line height for mixed EN / Myanmar.
  static const double lineHeightBody = 1.45;
  static const double lineHeightTitle = 1.25;
  static const double lineHeightCaption = 1.35;

  // Legacy aliases (keep call sites stable)
  static const double topBarTitleSize = fontTopBarTitle;
  static const double buttonFontSize = fontButton;
  static const double inputFontSize = fontBody;

  // —— Shadows ——
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardShadowElevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // —— Borders ——
  static BorderSide get borderSide =>
      const BorderSide(color: AppColors.border, width: 1);

  static BorderSide get borderSideLight =>
      const BorderSide(color: AppColors.borderLight, width: 0.5);

  static BorderSide get borderSideFocus =>
      const BorderSide(color: AppColors.primary, width: 1.5);

  // —— Primary light surfaces ——
  static BoxDecoration get primaryLightDecoration => BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: borderRadiusMd,
      );

  static BoxDecoration get primarySoftDecoration => BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: borderRadiusMd,
      );

  static BoxDecoration iconChipDecoration({
    double size = iconBox,
    BorderRadius? radius,
  }) =>
      BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: radius ?? borderRadiusSm,
      );

  // —— Decorations ——
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadiusMd,
        border: Border.fromBorderSide(borderSideLight),
        boxShadow: cardShadow,
      );

  static InputBorder get inputBorder => OutlineInputBorder(
        borderRadius: borderRadiusInput,
        borderSide: borderSide,
      );

  static InputBorder get inputFocusedBorder => OutlineInputBorder(
        borderRadius: borderRadiusInput,
        borderSide: borderSideFocus,
      );

  static InputBorder get inputErrorBorder => OutlineInputBorder(
        borderRadius: borderRadiusInput,
        borderSide: const BorderSide(color: AppColors.error),
      );
}
