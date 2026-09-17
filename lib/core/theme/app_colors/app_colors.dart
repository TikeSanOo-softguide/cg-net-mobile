import 'package:flutter/material.dart';

/// CG-NET brand color tokens.
class AppColors {
  AppColors._();

  /// Main brand blue — CTAs, header, nav, focus rings.
  /// Pure `#0100CA` only. Do not substitute similar blues or gradients.
  static const Color primary = Color(0xFF0100CA);

  /// Soft surfaces (icon chips, idle input wash). Not a primary surface.
  static const Color primaryLight = Color(0xFFEBEBFB);

  /// Softer wash (idle field fill / selected chips). Not a primary surface.
  static const Color primarySoft = Color(0xFFF5F5FD);

  /// Mid tint reserved for rare accents. Prefer [border] for idle outlines.
  static const Color primaryMuted = Color(0xFFB8B8F0);

  /// Accent yellow
  static const Color accent = Color(0xFFFFEE13);

  /// Dark ink for text on accent
  static const Color onAccent = Color(0xFF173236);

  /// Page background
  static const Color background = Color(0xFFEDF3F8);

  /// Alternate light surface
  static const Color backgroundAlt = Color(0xFFF7FAFC);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF5F6B64);
  static const Color textMuted = Color(0xFF64748B);

  static const Color border = Color(0xFFE0E3E5);
  static const Color borderLight = Color(0xFFF1F5F9);

  /// Ultra-thin paper edge for cards.
  static const Color paperBorder = Color(0xFFE8E8E8);

  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF1B7A4E);
}
