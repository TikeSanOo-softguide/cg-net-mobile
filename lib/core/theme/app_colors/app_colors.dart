import 'package:flutter/material.dart';

/// CG Net brand tokens aligned with Figma CG-NT Home.
class AppColors {
  AppColors._();

  /// Main brand blue (header, bottom nav, CTAs)
  static const Color primary = Color(0xFF0100CA);

  /// Accent yellow — Figma "secondary color"
  static const Color accent = Color(0xFFFFEE13);

  /// Dark ink (legacy brand / on-accent text)
  static const Color brandDark = Color(0xFF173236);

  /// Soft blue surfaces — Figma "Main back Ground"
  static const Color softBlue = Color(0xFFE2F1FF);

  /// Hover / chip blue
  static const Color hoverBlue = Color(0xFFB2D0F6);

  /// Page background — Figma "background"
  static const Color background = Color(0xFFEDF3F8);

  /// Alternate light surface — Figma "Exactly Use Color"
  static const Color backgroundAlt = Color(0xFFF7FAFC);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onAccent = Color(0xFF173236);

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
