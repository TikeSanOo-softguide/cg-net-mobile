import 'package:dio/dio.dart';

enum ApiFailure {
  offline,
  timeout,
  unauthorized,
  validation,
  tooManyRequests,
  server,
  cancelled,
  unknown,
}

class ApiException implements Exception {
  const ApiException(
    this.failure, {
    this.detail,
    this.statusCode,
    this.responseData,
    this.code,
    this.level,
  });

  final ApiFailure failure;
  final String? detail;
  final int? statusCode;
  final Object? responseData;
  final String? code;
  final String? level;

  String get messageKey => switch (failure) {
        ApiFailure.offline => 'api.offline',
        ApiFailure.timeout => 'api.timeout',
        ApiFailure.unauthorized => 'api.unauthorized',
        ApiFailure.validation => 'api.validation',
        ApiFailure.tooManyRequests => 'api.too_many_requests',
        ApiFailure.server => 'api.server',
        ApiFailure.cancelled => 'api.cancelled',
        ApiFailure.unknown => 'api.unknown',
      };

  static ApiException fromDio(DioException error) {
    if (CancelToken.isCancel(error) || error.type == DioExceptionType.cancel) {
      return const ApiException(ApiFailure.cancelled);
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return const ApiException(ApiFailure.timeout);
    }

    if (error.type == DioExceptionType.connectionError) {
      return const ApiException(ApiFailure.offline);
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;
    final detail = _detail(data);
    final code = _code(data);
    final level = _level(data);

    return switch (status) {
      401 => ApiException(
          ApiFailure.unauthorized,
          detail: detail,
          statusCode: status,
          responseData: data,
          code: code,
          level: level,
        ),
      409 => ApiException(
          ApiFailure.validation,
          detail: detail,
          statusCode: status,
          responseData: data,
          code: code,
          level: level,
        ),
      422 => ApiException(
          ApiFailure.validation,
          detail: detail,
          statusCode: status,
          responseData: data,
          code: code,
          level: level,
        ),
      429 => ApiException(
          ApiFailure.tooManyRequests,
          detail: detail,
          statusCode: status,
          responseData: data,
          code: code,
          level: level,
        ),
      final int statusCode when statusCode >= 500 => ApiException(
          ApiFailure.server,
          statusCode: statusCode,
          responseData: data,
          code: code,
          level: level,
        ),
      _ => ApiException(
          ApiFailure.unknown,
          detail: detail,
          statusCode: status,
          responseData: data,
          code: code,
          level: level,
        ),
    };
  }

  static String? _code(Object? data) {
    if (data is! Map) return null;
    final code = data['code']?.toString().trim().toUpperCase();
    if (code == null || !code.startsWith('MSG-')) return null;
    return code;
  }

  static String? _level(Object? data) {
    if (data is! Map) return null;
    final level = data['level']?.toString().trim().toLowerCase();
    if (level == 'error' || level == 'warning' || level == 'success') {
      return level;
    }
    return null;
  }

  static String? _detail(Object? data) {
    if (data is! Map) return null;
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    return null;
  }
}
