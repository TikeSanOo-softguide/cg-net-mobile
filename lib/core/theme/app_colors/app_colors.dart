import 'package:flutter/material.dart';

/// CG-NET brand color tokens.
class AppColors {
  AppColors._();

  /// Main brand blue — CTAs, header, nav, focus rings
  static const Color primary = Color(0xFF004AC6);

  /// Light primary surfaces (icon chips, soft fills, secondary buttons)
  static const Color primaryLight = Color(0xFFE2F1FF);

  /// Softer primary wash (hover / selected chips)
  static const Color primarySoft = Color(0xFFF3F8FF);

  /// Mid primary tint (pressed / hover borders)
  static const Color primaryMuted = Color(0xFFB2D0F6);

  /// Darker primary for gradients / emphasis
  static const Color primaryDark = Color(0xFF003A9E);

  /// Accent yellow
  static const Color accent = Color(0xFFFFEE13);

  /// Dark ink (on-accent text)
  static const Color brandDark = Color(0xFF173236);

  /// Legacy aliases → primary light family
  static const Color softBlue = primaryLight;
  static const Color hoverBlue = primaryMuted;

  /// Page background
  static const Color background = Color(0xFFEDF3F8);

  /// Alternate light surface
  static const Color backgroundAlt = Color(0xFFF7FAFC);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onAccent = Color(0xFF173236);

  /// Circular top-bar button fill (soft glass on primary)
  static const Color circleButtonFill = Color(0x2EFFFFFF);

  /// Alias for white-on-blue surfaces
  static const Color onSecondary = onPrimary;

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF5F6B64);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textSlate = Color(0xFF334155);

  static const Color border = Color(0xFFE0E3E5);
  static const Color borderLight = Color(0xFFF1F5F9);

  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF1B7A4E);

  /// Alias kept for older call sites that used `secondary`
  static const Color secondary = primary;
}
