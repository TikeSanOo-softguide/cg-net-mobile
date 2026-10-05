import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class PackageBuyApiResult {
  const PackageBuyApiResult({
    required this.isSuccess,
    this.message,
    this.transactionNo,
  });

  final bool isSuccess;
  final String? message;
  final String? transactionNo;
}

class PackageBuyRepository {
  PackageBuyRepository(this._dio);

  final Dio _dio;

  Future<PackageBuyApiResult> buyPackage({
    required int packageId,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.packagesBuy,
        data: {'package_id': packageId},
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
        ),
      );
      final root = _asMap(response.data);
      final data = _asMap(root['data']);
      final success = _resolveSuccess(response.statusCode, root);

      return PackageBuyApiResult(
        isSuccess: success,
        message: root['message']?.toString(),
        transactionNo: root['transaction_no']?.toString() ??
            data['transaction_no']?.toString() ??
            data['id']?.toString(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static bool _resolveSuccess(int? statusCode, Map<String, dynamic> data) {
    final explicit = data['success'];
    if (explicit is bool) return explicit;
    if (explicit is num) return explicit != 0;
    if (explicit is String) {
      final lower = explicit.toLowerCase();
      if (lower == 'true' || lower == 'ok' || lower == 'success') return true;
      if (lower == 'false' || lower == 'error' || lower == 'failed') {
        return false;
      }
    }
    return (statusCode ?? 500) >= 200 && (statusCode ?? 500) < 300;
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return const {};
  }
}

final packageBuyRepositoryProvider = Provider<PackageBuyRepository>((ref) {
  return PackageBuyRepository(ref.watch(dioProvider));
});
