import 'package:flutter/material.dart';

/// Shared timing and neutral colors for every skeleton.
class ShimmerConfig {
  const ShimmerConfig._();

  static const duration = Duration(milliseconds: 1400);

  static const Color lightBase = Color(0xFFE4EAF2);
  static const Color lightHighlight = Color(0xFFF6F8FB);
  static const Color darkBase = Color(0xFF2C3544);
  static const Color darkHighlight = Color(0xFF3C4758);

  static Color base(Brightness brightness) {
    return brightness == Brightness.dark ? darkBase : lightBase;
  }

  static Color highlight(Brightness brightness) {
    return brightness == Brightness.dark ? darkHighlight : lightHighlight;
  }

  static Color card(Brightness brightness) {
    return brightness == Brightness.dark
        ? const Color(0xFF1B2330)
        : const Color(0xFFFFFFFF);
  }
}
