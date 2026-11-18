import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeviceIdentity {
  DeviceIdentity({
    required String id,
    required String name,
    required String platform,
    required String appVersion,
  })  : id = sanitizeDeviceId(id),
        name = sanitizeHeaderValue(name, max: 80),
        platform = sanitizePlatform(platform),
        appVersion = sanitizeHeaderValue(appVersion, max: 20, fallback: '1.0.0');

  static const fallbackVersion = '1.0.0';

  final String id;
  final String name;
  final String platform;
  final String appVersion;

  String get userAgent => 'cg-net-mobile/$appVersion ($platform; $name)';

  static String newId() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  static bool isDeviceId(String value) =>
      RegExp(r'^[A-Za-z0-9-]{8,64}$').hasMatch(value);

  static String sanitizeDeviceId(String value) {
    final trimmed = value.trim();
    return isDeviceId(trimmed) ? trimmed : newId();
  }

  static String sanitizePlatform(String value) {
    final platform = value.trim().toLowerCase();
    return platform == 'ios' || platform == 'web' ? platform : 'android';
  }

  static String sanitizeHeaderValue(
    String value, {
    int max = 80,
    String fallback = 'unknown',
  }) {
    final cleaned = value
        .replaceAll(RegExp(r'[^A-Za-z0-9 ._()/-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return fallback;
    return cleaned.length <= max ? cleaned : cleaned.substring(0, max).trim();
  }
}

/// Null until [main] loads the install id and phone name.
final deviceIdentityProvider = Provider<DeviceIdentity?>((ref) => null);
