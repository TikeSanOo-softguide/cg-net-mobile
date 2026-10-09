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

  /// Page canvas — cool blue-gray like KPay content zone (cards stay pure white).
  static const Color background = Color(0xFFEDF1F7);

  /// Alternate light surface (cool wash).
  static const Color backgroundAlt = Color(0xFFF5F8FC);

  /// Crisp clear card white.
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF0B1220);
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF616A78);

  static const Color border = Color(0xFFD9E0EA);
  static const Color borderLight = Color(0xFFE8EEF5);

  /// Cool hairline for crisp white cards.
  static const Color paperBorder = Color(0xFFE2E8F0);

  /// Thin translucent cool rim for a glass edge.
  static const Color glassBorder = Color(0x73D5DEEA);

  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF1B7A4E);
  static const Color warning = Color(0xFFF57C00);
}
