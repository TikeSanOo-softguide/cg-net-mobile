import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class DeviceTokenRepository {
  DeviceTokenRepository(this._dio);

  final Dio _dio;

  Future<void> register(String token) => _send(
        () => _dio.post<dynamic>(
          ApiEndpoints.deviceTokens,
          data: {'token': token, 'platform': _platform},
        ),
      );

  Future<void> remove(String token) => _send(
        () => _dio.delete<dynamic>(
          ApiEndpoints.deviceTokens,
          data: {'token': token},
        ),
      );

  Future<void> _send(Future<Response<dynamic>> Function() request) async {
    try {
      await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static String get _platform {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  }
}

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(dioProvider));
});
