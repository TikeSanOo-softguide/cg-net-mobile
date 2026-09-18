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
        letterSpacing: 0.8,
        height: 1.15,
      );

  static TextStyle sectionTitle({Color? color}) => english(
        fontSize: AppStyle.fontSectionTitle,
        fontWeight: FontWeight.w600,
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

  static TextStyle caption(
          {Color? color, FontWeight weight = FontWeight.w400}) =>
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

  /// Explicit scheme — pure `#0100CA` primary, no seed-derived blues.
  /// Soft blues stay on [AppColors.primaryLight]/[AppColors.primarySoft] only
  /// when UI code opts in; Material containers use neutrals so M3 never invents
  /// a lighter primary surface automatically.
  static ColorScheme get _colorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.backgroundAlt,
        onPrimaryContainer: AppColors.primary,
        secondary: AppColors.accent,
        onSecondary: AppColors.onAccent,
        secondaryContainer: AppColors.backgroundAlt,
        onSecondaryContainer: AppColors.onAccent,
        tertiary: AppColors.backgroundAlt,
        onTertiary: AppColors.textPrimary,
        tertiaryContainer: AppColors.borderLight,
        onTertiaryContainer: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.onPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.border,
        outlineVariant: AppColors.borderLight,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        inverseSurface: AppColors.textPrimary,
        onInverseSurface: AppColors.onPrimary,
        inversePrimary: AppColors.onPrimary,
        surfaceTint: Color(0x00000000),
      );

  static ThemeData get light {
    final colorScheme = _colorScheme;

    final baseText = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      applyElevationOverlayColor: false,
      colorScheme: colorScheme,
      primaryColor: AppColors.primary,
      fontFamily: englishFontFamily,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      dividerColor: AppColors.border,
      // Neutral ink — never splash a translucent primary blue over UI.
      splashColor: Colors.black.withValues(alpha: 0.06),
      highlightColor: Colors.black.withValues(alpha: 0.04),
      hoverColor: Colors.black.withValues(alpha: 0.03),
      focusColor: Colors.black.withValues(alpha: 0.06),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          overlayColor: Colors.transparent,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
        ),
      ),
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
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
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
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.primary,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyle.borderRadiusMd,
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          minimumSize: const Size.fromHeight(AppStyle.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyle.borderRadiusButton,
          ),
          textStyle: button(color: AppColors.onPrimary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          minimumSize: const Size.fromHeight(AppStyle.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyle.borderRadiusButton,
          ),
          textStyle: button(color: AppColors.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary,
          disabledForegroundColor: AppColors.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          side: BorderSide.none,
          minimumSize: const Size.fromHeight(AppStyle.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: AppStyle.borderRadiusButton,
          ),
          textStyle: button(color: AppColors.onPrimary),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          textStyle: button(color: AppColors.primary),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surface;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textMuted;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onPrimary;
          }
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.border;
        }),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.borderLight,
        circularTrackColor: AppColors.borderLight,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        dividerColor: AppColors.borderLight,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        backgroundColor: AppColors.surface,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.backgroundAlt,
        selectedColor: AppColors.primary,
        disabledColor: AppColors.borderLight,
        labelStyle: caption(color: AppColors.primary, weight: FontWeight.w600),
        secondaryLabelStyle: caption(color: AppColors.onPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
        selectedColor: AppColors.primary,
        selectedTileColor: AppColors.backgroundAlt,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyle.borderRadiusLg,
        ),
        titleTextStyle: pageTitle(),
        contentTextStyle: body(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppStyle.radiusCurve),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary,
        contentTextStyle: body(color: AppColors.onPrimary),
        actionTextColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyle.borderRadiusSm,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.primary,
        size: AppStyle.iconSizeLg,
      ),
      primaryIconTheme: const IconThemeData(
        color: AppColors.onPrimary,
        size: AppStyle.iconSizeLg,
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
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primary,
        // Solid soft token — not alpha-blended primary.
        selectionColor: AppColors.primaryLight,
        selectionHandleColor: AppColors.primary,
      ),
    );
  }
}
