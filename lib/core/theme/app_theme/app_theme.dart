import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app_colors/app_colors.dart';
import '../app_style/app_style.dart';

class AppTheme {
  AppTheme._();

  /// Primary UI typeface (EN + shared Latin).
  static String? get englishFontFamily =>
      GoogleFonts.plusJakartaSans().fontFamily;

  static TextStyle english({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // —— Semantic text styles ——

  static TextStyle hero({Color? color}) => english(
        fontSize: AppStyle.fontHero,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: AppStyle.lineHeightTitle,
      );

  static TextStyle amount({Color? color}) => english(
        fontSize: AppStyle.fontAmount,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: AppStyle.lineHeightTitle,
      );

  static TextStyle pageTitle({Color? color}) => english(
        fontSize: AppStyle.fontPageTitle,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: AppStyle.lineHeightTitle,
      );

  static TextStyle topBarTitle({Color? color}) => english(
        fontSize: AppStyle.fontTopBarTitle,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.onPrimary,
        letterSpacing: 0.2,
        height: 1.15,
      );

  static TextStyle sectionTitle({Color? color}) => english(
        fontSize: AppStyle.fontSectionTitle,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        height: AppStyle.lineHeightTitle,
      );

  static TextStyle cardTitle({Color? color}) => english(
        fontSize: AppStyle.fontCardTitle,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
        height: AppStyle.lineHeightTitle,
      );

  static TextStyle body({Color? color, FontWeight weight = FontWeight.w400}) =>
      english(
        fontSize: AppStyle.fontBody,
        fontWeight: weight,
        color: color ?? AppColors.textPrimary,
        height: AppStyle.lineHeightBody,
      );

  static TextStyle bodySecondary({Color? color}) => english(
        fontSize: AppStyle.fontSecondary,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
        height: AppStyle.lineHeightBody,
      );

  static TextStyle caption({Color? color, FontWeight weight = FontWeight.w400}) =>
      english(
        fontSize: AppStyle.fontCaption,
        fontWeight: weight,
        color: color ?? AppColors.textMuted,
        height: AppStyle.lineHeightCaption,
      );

  static TextStyle captionSm({Color? color}) => english(
        fontSize: AppStyle.fontCaptionSm,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textMuted,
        height: AppStyle.lineHeightCaption,
      );

  static TextStyle button({Color? color}) => english(
        fontSize: AppStyle.fontButton,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.2,
      );

  static TextStyle navLabel({
    required bool selected,
    Color? color,
  }) =>
      english(
        fontSize: AppStyle.bottomNavLabelSize,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: color,
        height: 1.15,
      );

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.accent,
      tertiary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.error,
      brightness: Brightness.light,
    );

    final baseText = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: englishFontFamily,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: baseText.copyWith(
        headlineMedium: hero(),
        titleLarge: pageTitle(),
        titleMedium: sectionTitle(),
        titleSmall: cardTitle(),
        bodyLarge: body(color: AppColors.textPrimary),
        bodyMedium: bodySecondary(),
        bodySmall: caption(),
        labelLarge: button(color: AppColors.onPrimary),
        labelMedium: caption(weight: FontWeight.w500),
        labelSmall: captionSm(),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        toolbarHeight: AppStyle.topBarHeight,
        iconTheme: const IconThemeData(
          color: AppColors.onPrimary,
          size: AppStyle.iconSizeLg,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.onPrimary,
          size: AppStyle.iconSizeLg,
        ),
        titleTextStyle: topBarTitle(),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyle.borderRadiusMd,
          side: AppStyle.borderSideLight,
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size.fromHeight(AppStyle.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyle.borderRadiusButton,
          ),
          textStyle: button(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(AppStyle.controlHeight),
          side: AppStyle.borderSide,
          shape: RoundedRectangleBorder(
            borderRadius: AppStyle.borderRadiusButton,
          ),
          textStyle: button(color: AppColors.primary),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyle.spaceMd,
          vertical: AppStyle.spaceMd,
        ),
        border: AppStyle.inputBorder,
        enabledBorder: AppStyle.inputBorder,
        focusedBorder: AppStyle.inputFocusedBorder,
        errorBorder: AppStyle.inputErrorBorder,
        focusedErrorBorder: AppStyle.inputErrorBorder,
        prefixIconColor: AppColors.primary,
        suffixIconColor: AppColors.primary,
      ),
    );
  }
}
