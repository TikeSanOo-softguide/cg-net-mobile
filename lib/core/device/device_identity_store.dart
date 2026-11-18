import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../storage/secure_storage/secure_storage.dart';
import 'device_identity.dart';

class DeviceIdentityStore {
  DeviceIdentityStore(this._storage);

  final SecureStorage _storage;

  Future<DeviceIdentity> load() async {
    return DeviceIdentity(
      id: await _deviceId(),
      name: await _deviceName(),
      platform: _platform,
      appVersion: await _appVersion(),
    );
  }

  String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }

  Future<String> _deviceId() async {
    try {
      final existing = await _storage.readDeviceId();
      if (existing != null && DeviceIdentity.isDeviceId(existing)) {
        return existing;
      }
      final created = DeviceIdentity.newId();
      await _storage.writeDeviceId(created);
      return created;
    } catch (error) {
      debugPrint('[device] id storage unavailable: $error');
      return DeviceIdentity.newId();
    }
  }

  Future<String> _deviceName() async {
    if (kIsWeb) return 'Web';
    try {
      final plugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await plugin.androidInfo;
        return _joinName(info.manufacturer, info.model);
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final model = (await plugin.iosInfo).model.trim();
        return model.isEmpty ? 'iPhone' : model;
      }
    } catch (error) {
      debugPrint('[device] name unavailable: $error');
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? 'iPhone' : 'Android';
  }

  Future<String> _appVersion() async {
    try {
      final version = (await PackageInfo.fromPlatform()).version.trim();
      if (version.isNotEmpty) return version;
    } catch (error) {
      debugPrint('[device] version unavailable: $error');
    }
    return DeviceIdentity.fallbackVersion;
  }

  String _joinName(String manufacturer, String model) {
    final brand = manufacturer.trim();
    final phone = model.trim();
    if (brand.isEmpty) return phone.isEmpty ? 'Android' : phone;
    if (phone.isEmpty) return brand;
    if (phone.toLowerCase().startsWith(brand.toLowerCase())) return phone;
    final label = brand[0].toUpperCase() + brand.substring(1);
    return '$label $phone';
  }
}
