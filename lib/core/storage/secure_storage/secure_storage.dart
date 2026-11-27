import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;
  Future<void> _tokenMutationTail = Future<void>.value();

  static const _tokenKey = 'auth_token';
  static const _profileCacheKey = 'cached_user_profile';
  static const _onboardingKey = 'onboarding_done';
  static const _deviceIdKey = 'device_id';

  Future<void> writeToken(String token) => _withTokenMutation(() async {
        await _storage.delete(key: _profileCacheKey);
        await _storage.write(key: _tokenKey, value: token);
      });

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _withTokenMutation(_clearToken);

  Future<void> _clearToken() async {
    if (kDebugMode) {
      debugPrint(
          '[auth] clearToken requested; tokenPresent=${await hasToken()}');
    }
    await _storage.delete(key: _profileCacheKey);
    await _storage.delete(key: _tokenKey);
    if (kDebugMode) {
      debugPrint(
          '[auth] clearToken completed; tokenPresent=${await hasToken()}');
    }
  }

  Future<bool> clearTokenIfMatches(String expectedToken) =>
      _withTokenMutation(() async {
        final currentToken = await readToken();
        if (currentToken != expectedToken) {
          if (kDebugMode) {
            debugPrint('[auth] skipped token clear; stored token has changed');
          }
          return false;
        }

        await _clearToken();
        return true;
      });

  Future<String?> readCachedProfile() => _storage.read(key: _profileCacheKey);

  Future<void> writeCachedProfile(String profile) =>
      _storage.write(key: _profileCacheKey, value: profile);

  Future<void> clearCachedProfile() => _storage.delete(key: _profileCacheKey);

  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> setOnboardingDone(bool value) =>
      _storage.write(key: _onboardingKey, value: value.toString());

  Future<bool> isOnboardingDone() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  Future<String?> readDeviceId() => _storage.read(key: _deviceIdKey);

  Future<void> writeDeviceId(String id) =>
      _storage.write(key: _deviceIdKey, value: id);

  Future<void> clearAll() => _withTokenMutation(() => _storage.deleteAll());

  Future<T> _withTokenMutation<T>(Future<T> Function() action) {
    final previous = _tokenMutationTail;
    final completed = Completer<void>();
    _tokenMutationTail = completed.future;

    Future<T> run() async {
      await previous;
      try {
        return await action();
      } finally {
        completed.complete();
      }
    }

    return run();
  }
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});
