import 'package:android_id/android_id.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class DeviceIdException implements Exception {
  const DeviceIdException();
}

class DeviceIdService {
  DeviceIdService({
    FlutterSecureStorage? storage,
    Future<String?> Function()? androidIdReader,
    String Function()? uuidGenerator,
    bool? isAndroid,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            ),
        _androidIdReader = androidIdReader ?? const AndroidId().getId,
        _uuidGenerator = uuidGenerator ?? const Uuid().v4,
        _isAndroid = isAndroid ??
            (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static const _deviceIdStorageKey = 'auth_device_id';
  static const _fallbackUuidStorageKey = 'auth_device_uuid';
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );
  static const _androidOptions =
      AndroidOptions(encryptedSharedPreferences: true);

  final FlutterSecureStorage _storage;
  final Future<String?> Function() _androidIdReader;
  final String Function() _uuidGenerator;
  final bool _isAndroid;

  String? _cachedId;
  Future<String>? _inFlight;

  Future<String> getDeviceId() async {
    final cachedId = _cachedId;
    if (cachedId != null) return cachedId;

    final pending = _inFlight ??= _loadDeviceId();
    try {
      final id = await pending;
      _cachedId = id;
      return id;
    } finally {
      if (identical(_inFlight, pending)) _inFlight = null;
    }
  }

  Future<String> _loadDeviceId() async {
    final storedId = await _readStoredDeviceId();
    if (storedId != null) return storedId;

    if (_isAndroid) {
      try {
        final androidId = await _androidIdReader();
        final normalizedId = androidId?.trim();
        if (normalizedId != null && normalizedId.isNotEmpty) {
          final deviceId = 'android:$normalizedId';
          await _persistAndroidId(deviceId);
          return deviceId;
        }
      } on MissingPluginException {
        // Use the persistent UUID fallback when the native plugin is unavailable.
      } on PlatformException {
        // Use the persistent UUID fallback when Android ID cannot be read.
      }
    }

    final savedUuid = await _readStoredUuid();
    if (savedUuid != null) {
      return 'ios:$savedUuid';
    }

    final uuid = _uuidGenerator();
    try {
      await _storage.write(
        key: _fallbackUuidStorageKey,
        value: uuid,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
      return 'ios:$uuid';
    } on MissingPluginException {
      throw const DeviceIdException();
    } on PlatformException {
      throw const DeviceIdException();
    }
  }

  Future<String?> _readStoredDeviceId() async {
    try {
      final storedId = await _storage.read(
        key: _deviceIdStorageKey,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
      if (storedId == null || storedId.isEmpty) return null;
      if (storedId.startsWith('android:') || storedId.startsWith('ios:')) {
        return storedId;
      }
      return null;
    } on MissingPluginException {
      if (_isAndroid) return null;
      throw const DeviceIdException();
    } on PlatformException {
      if (_isAndroid) return null;
      throw const DeviceIdException();
    }
  }

  Future<void> _persistAndroidId(String deviceId) async {
    try {
      await _storage.write(
        key: _deviceIdStorageKey,
        value: deviceId,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
    } on MissingPluginException {
      debugPrint('[device] secure storage unavailable; using Android ID');
    } on PlatformException {
      debugPrint('[device] could not cache Android ID in secure storage');
    }
  }

  Future<String?> _readStoredUuid() async {
    try {
      final savedUuid = await _storage.read(
        key: _fallbackUuidStorageKey,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      );
      return savedUuid == null || savedUuid.isEmpty ? null : savedUuid;
    } on MissingPluginException {
      if (_isAndroid) return null;
      throw const DeviceIdException();
    } on PlatformException {
      if (_isAndroid) return null;
      throw const DeviceIdException();
    }
  }
}

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService();
});
