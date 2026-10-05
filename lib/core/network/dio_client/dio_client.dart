import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_endpoints/api_endpoints.dart';
import '../auth_interceptor/auth_interceptor.dart';
import '../get_retry_interceptor.dart';
import '../locale_interceptor.dart';

class DioClient {
  DioClient({
    required AuthInterceptor authInterceptor,
    required String Function() languageCode,
  }) {
    final baseUrl = ApiEndpoints.baseUrl;
    // Helps confirm real-phone builds are not still pointing at 127.0.0.1.
    debugPrint('[api] baseUrl=$baseUrl');
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      LocaleInterceptor(languageCode),
      authInterceptor,
      GetRetryInterceptor(_dio),
      if (kDebugMode)
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('[api] ${options.method} ${options.uri}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint(
              '[api] ${response.statusCode} ${response.requestOptions.uri}',
            );
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint(
              '[api] ${error.response?.statusCode ?? error.type} ${error.requestOptions.uri}',
            );
            handler.next(error);
          },
        ),
    ]);
  }

  late final Dio _dio;

  Dio get dio => _dio;
}

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(
    authInterceptor: ref.watch(authInterceptorProvider),
    languageCode: ref.watch(languageCodeProvider),
  );
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});
