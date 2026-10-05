import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storage/local_prefs/local_prefs.dart';
import '../../storage/secure_storage/secure_storage.dart';
import '../session_clock.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage, this._onUnauthorized);

  final SecureStorage _secureStorage;
  final void Function() _onUnauthorized;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _secureStorage.clearToken();
      _onUnauthorized();
    }
    handler.next(err);
  }
}

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    ref.watch(secureStorageProvider),
    () => ref.read(sessionClockProvider).expire(),
  );
});

final languageCodeProvider = Provider<String Function()>((ref) {
  return () => ref.read(localPrefsProvider).languageCode ?? 'en';
});
