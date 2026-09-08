import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_endpoints/api_endpoints.dart';
import '../auth_interceptor/auth_interceptor.dart';

class DioClient {
  DioClient(this._authInterceptor) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    _dio.interceptors.addAll([
      _authInterceptor,
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }

  late final Dio _dio;
  final AuthInterceptor _authInterceptor;

  Dio get dio => _dio;
}

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient(ref.watch(authInterceptorProvider));
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).dio;
});
