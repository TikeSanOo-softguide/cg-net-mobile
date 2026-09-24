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
  static const double spaceXl = 15;
  static const double spaceXxl = 24;
  static const double spaceXxxl = 32;

  /// Horizontal page inset (screen edge → content).
  static const double pageMarginH = 16;
  static const EdgeInsets pagePadding = EdgeInsets.all(spaceXxl);
  static const EdgeInsets pagePaddingH =
      EdgeInsets.symmetric(horizontal: pageMarginH);
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceLg);
  static const EdgeInsets sectionGap = EdgeInsets.only(bottom: spaceXl);

  // —— Radius ——
  static const double radiusSm = 10;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  /// Default curved sheet / top-bar join radius (login uses 30 via override).
  static const double radiusCurve = 24;
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
  static BorderRadius get borderRadiusCurve =>
      const BorderRadius.vertical(top: Radius.circular(radiusCurve));

  // —— Control sizes ——
  static const double controlHeight = 46;
  static const double iconSize = 20;
  static const double iconSizeSm = 18;
  static const double iconSizeLg = 22;
  static const double iconBox = 40;
  static const double circleButtonSize = 30;
  static const double topBarHeight = 40;
  static const double bottomNavHeight = 64;
  static const double bottomNavIconSize = 20;
  static const double bottomNavLabelSize = 11;
  static const double bottomNavIconGap = 4;

  // —— Typography sizes ——
  static const double fontHero = 28;
  static const double fontPageTitle = 22;
  static const double fontTopBarTitle = 15;
  static const double fontSectionTitle = 14;
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

  static const double inputFontSize = fontBody;

  // —— Shadows ——
  static List<BoxShadow> get cardShadow => const <BoxShadow>[];

  static List<BoxShadow> get cardShadowElevated => const <BoxShadow>[];

  // —— Borders ——
  static BorderSide get borderSide =>
      const BorderSide(color: AppColors.paperBorder, width: 1);

  static BorderSide get borderSideLight =>
      const BorderSide(color: AppColors.borderLight, width: 0.5);

  /// Thin hairline for cards.
  static BorderSide get borderSidePaper =>
      const BorderSide(color: Color(0xFFFFFFFF), width: 0.1);

  static BorderSide get borderSideFocus =>
      const BorderSide(color: AppColors.primary, width: 1.5);

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
        borderRadius: borderRadiusSm,
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
