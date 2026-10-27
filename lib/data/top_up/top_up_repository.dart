import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/message_codes.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class TopUpSerialCheckResult {
  const TopUpSerialCheckResult({
    required this.result,
    this.message,
  });

  final TopUpSerialCheckStatus result;
  final String? message;

  bool get isValid => result == TopUpSerialCheckStatus.valid;
}

enum TopUpSerialCheckStatus {
  valid,
  alreadyUsed,
  invalid,
}

class TopUpAccountResult {
  const TopUpAccountResult({
    required this.isSuccess,
    this.message,
    this.amountPoints,
    this.balancePoints,
    this.transactionNo,
  });

  final bool isSuccess;
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
      final data = _asMap(response.data);
      return _serialCheckResult(response.statusCode, data);
    } on DioException catch (error) {
      final data = _asMap(error.response?.data);
      final statusCode = error.response?.statusCode;
      if (statusCode == 400) {
        return _serialCheckResult(statusCode, data);
      }
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
        ),
      );

      final root = _asMap(response.data);
      final nestedData = _asMap(root['data']);
      final success = _resolveSuccess(response.statusCode, root);

      return TopUpAccountResult(
        isSuccess: success,
        message: _responseMessage(root),
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

  static TopUpSerialCheckResult _serialCheckResult(
    int? statusCode,
    Map<String, dynamic> data,
  ) {
    final result = _serialCheckStatus(data['result']) ??
        (_resolveSuccess(statusCode, data)
            ? TopUpSerialCheckStatus.valid
            : TopUpSerialCheckStatus.invalid);

    return TopUpSerialCheckResult(
      result: result,
      message: _responseMessage(data),
    );
  }

  static TopUpSerialCheckStatus? _serialCheckStatus(Object? value) {
    return switch (value) {
      'valid' => TopUpSerialCheckStatus.valid,
      'already_used' => TopUpSerialCheckStatus.alreadyUsed,
      'invalid_card' => TopUpSerialCheckStatus.invalid,
      _ => null,
    };
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String? _responseMessage(Map<String, dynamic> root) {
    final code = root['code']?.toString().trim().toUpperCase();
    if (MessageCodes.isKnown(code)) return code;

    final rootMessage = root['message'];
    if (rootMessage is String && rootMessage.trim().isNotEmpty) {
      return rootMessage;
    }

    final dataMessage = _asMap(root['data'])['message'];
    if (dataMessage is String && dataMessage.trim().isNotEmpty) {
      return dataMessage;
    }

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
