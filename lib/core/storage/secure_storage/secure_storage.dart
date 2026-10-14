import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _profileCacheKey = 'cached_user_profile';
  static const _onboardingKey = 'onboarding_done';

  Future<void> writeToken(String token) async {
    await _storage.delete(key: _profileCacheKey);
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() async {
    await _storage.delete(key: _profileCacheKey);
    await _storage.delete(key: _tokenKey);
  }

  Future<String?> readCachedProfile() =>
      _storage.read(key: _profileCacheKey);

  Future<void> writeCachedProfile(String profile) =>
      _storage.write(key: _profileCacheKey, value: profile);

  Future<void> clearCachedProfile() =>
      _storage.delete(key: _profileCacheKey);

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

  Future<void> clearAll() => _storage.deleteAll();
}

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});
