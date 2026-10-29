import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class DeactivateAccountRepository {
  const DeactivateAccountRepository(this._dio);

  final Dio _dio;

  Future<String?> deactivate({required String password}) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.deactivateAccount,
        data: {'password': password},
      );
      final data = response.data;
      if (data is! Map) return null;

      final message = data['message']?.toString().trim();
      return message == null || message.isEmpty ? null : message;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final deactivateAccountRepositoryProvider =
    Provider<DeactivateAccountRepository>((ref) {
  return DeactivateAccountRepository(ref.watch(dioProvider));
});
