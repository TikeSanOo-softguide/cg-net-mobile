import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../storage/list_snapshot_store.dart';
import '../api_exception.dart';
import '../../storage/local_prefs/local_prefs.dart';
import '../../storage/secure_storage/secure_storage.dart';
import '../session_clock.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
      this._secureStorage, this._sessionClock, this._onUnauthorized);

  static const requireAuthKey = 'require_auth';
  static const publicKey = 'public';
  static const Set<String> _publicPaths = {
    '/auth/otp/request',
    '/auth/otp/verify',
    '/auth/session/check',
    '/auth/login',
    '/auth/register',
    '/offices',
    '/locations',
    '/states',
    '/announcements',
    '/inbox',
    '/app-version',
  };
  static const List<String> _publicPrefixes = [
    '/web-app/',
    '/general-settings/',
  ];
  static final RegExp _stateRegionsPath = RegExp(r'^/states/[^/]+/regions$');
  static final RegExp _regionAreasPath = RegExp(r'^/regions/[^/]+/areas$');

  final SecureStorage _secureStorage;
  final SessionClock _sessionClock;
  final void Function() _onUnauthorized;

  bool _requiresAuth(RequestOptions options) {
    if (options.extra[publicKey] == true) return false;
    if (options.extra[requireAuthKey] == true) return true;

    final path = _normalizePath(options.path);
    final isPublic = _publicPaths.contains(path) ||
        _publicPrefixes.any(path.startsWith) ||
        _stateRegionsPath.hasMatch(path) ||
        _regionAreasPath.hasMatch(path);
    return !isPublic;
  }

  String _normalizePath(String path) {
    final uri = Uri.tryParse(path);
    var cleanPath = uri?.path ?? path;
    cleanPath = cleanPath.split('?').first;
    if (cleanPath.isEmpty) return '/';
    if (!cleanPath.startsWith('/')) cleanPath = '/$cleanPath';

    if (cleanPath == '/api') return '/';
    if (cleanPath.startsWith('/api/')) {
      cleanPath = cleanPath.substring('/api'.length);
    }
    return cleanPath;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final needsAuth = _requiresAuth(options);
    final token = await _secureStorage.readToken();
    if ((token == null || token.isEmpty) && needsAuth) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: const ApiException(ApiFailure.unauthorized),
        ),
      );
      return;
    }
    if (needsAuth && !_sessionClock.authenticated) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.cancel,
          error: const ApiException(ApiFailure.unauthorized),
        ),
      );
      return;
    }
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
    final requestToken = _requestToken(err.requestOptions);
    if (err.response?.statusCode == 401 && requestToken != null) {
      if (await _secureStorage.clearTokenIfMatches(requestToken)) {
        _onUnauthorized();
      }
    }
    handler.next(err);
  }

  String? _requestToken(RequestOptions options) {
    String? authorization;
    for (final entry in options.headers.entries) {
      if (entry.key.toLowerCase() == 'authorization' && entry.value is String) {
        authorization = entry.value as String;
        break;
      }
    }
    if (authorization == null) return null;

    final match = RegExp(
      r'^Bearer\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(authorization.trim());
    final token = match?.group(1)?.trim();
    return token == null || token.isEmpty ? null : token;
  }
}

final authInterceptorProvider = Provider<AuthInterceptor>((ref) {
  return AuthInterceptor(
    ref.watch(secureStorageProvider),
    ref.read(sessionClockProvider),
    () {
      final preferences = ref.read(sharedPreferencesProvider);
      preferences
        ..remove(LocalPrefs.inboxCacheKey)
        ..remove(LocalPrefs.chatCacheKey)
        ..remove(LocalPrefs.sessionUserIdKey);
      ListSnapshotStore(preferences).clear();
      ref.read(sessionClockProvider).expire();
    },
  );
});

final languageCodeProvider = Provider<String Function()>((ref) {
  return () => ref.read(localPrefsProvider).languageCode ?? 'en';
});
