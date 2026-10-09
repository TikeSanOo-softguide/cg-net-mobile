import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import 'package:flutter/foundation.dart';

class BroadbandRepository {
  BroadbandRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> connect({
    required String accountNumber,
    required String customerName,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.broadbandBind,
        data: {
          'account_number': accountNumber,
          'customer_name': customerName,
        },
      );

      return response.data ?? {};
    } on DioException catch (error) {
      final apiException = ApiException.fromDio(error);
      throw ApiException(
        apiException.failure,
        detail: _responseMessage(error.response?.data) ?? apiException.detail,
      );
    }
  }

  Future<Map<String, dynamic>> unbindAccount({
    required String accountNumber,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.broadbandUnbind,
        data: {
          'account_number': accountNumber,
        },
      );

      return response.data ?? {};
    } on DioException catch (error) {
      final apiException = ApiException.fromDio(error);
      throw ApiException(
        apiException.failure,
        detail: _responseMessage(error.response?.data) ?? apiException.detail,
      );
    }
  }

  static String? _responseMessage(Object? data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is! String || message.trim().isEmpty) return null;
    return message.trim();
  }
}

final broadbandRepositoryProvider = Provider<BroadbandRepository>((ref) {
  return BroadbandRepository(ref.watch(dioProvider));
});
