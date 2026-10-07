import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class TopUpSerialCheckResult {
  const TopUpSerialCheckResult({
    required this.isValid,
    this.message,
    this.amountPoints,
  });

  final bool isValid;
  final String? message;
  final int? amountPoints;
}

class TopUpAccountResult {
  const TopUpAccountResult({
    required this.isSuccess,
    required this.statusCode,
    this.message,
    this.amountPoints,
    this.balancePoints,
    this.transactionNo,
  });

  final bool isSuccess;
  final int? statusCode;
  final String? message;
  final int? amountPoints;
  final int? balancePoints;
  final String? transactionNo;
}

class TopUpRepository {
  TopUpRepository(this._dio);

  final Dio _dio;

  Future<TopUpSerialCheckResult> checkSerialNo(String serialNo) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.redeemCheckSerialNo,
        data: {'serial_no': serialNo},
      );
      // print('Top-up response: ${response.data}');
      final data = _asMap(response.data);
      final success = _resolveSuccess(response.statusCode, data);

      return TopUpSerialCheckResult(
        isValid: success,
        message: data['message']?.toString(),
        amountPoints: _toInt(data['amount']),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<TopUpAccountResult> topUpAccount({
    required String phone,
    required String pin,
    required String idempotencyKey,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.redeemTopUpAccount,
        data: {'phone': phone, 'pin': pin},
        options: Options(
          headers: {'Idempotency-Key': idempotencyKey},
          validateStatus: (status) =>
              status == 200 || status == 400 || status == 409,
        ),
      );

      final root = _asMap(response.data);
      final nestedData = _asMap(root['data']);
      final statusCode = response.statusCode;
      return TopUpAccountResult(
        isSuccess: statusCode == 200 && root['success'] == true,
        statusCode: statusCode,
        message: root['message']?.toString(),
        amountPoints: _toInt(root['amount']) ?? _toInt(nestedData['amount']),
        balancePoints: _toInt(root['balance']) ?? _toInt(nestedData['balance']),
        transactionNo: root['transaction_no']?.toString() ??
            nestedData['transaction_no']?.toString(),
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

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
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

final topUpRepositoryProvider = Provider<TopUpRepository>((ref) {
  return TopUpRepository(ref.watch(dioProvider));
});
