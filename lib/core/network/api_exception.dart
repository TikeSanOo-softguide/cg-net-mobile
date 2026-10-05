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
  const ApiException(this.failure, {this.detail});

  final ApiFailure failure;
  final String? detail;

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
    final detail = _detail(error.response?.data);

    return switch (status) {
      401 => ApiException(ApiFailure.unauthorized, detail: detail),
      422 => ApiException(ApiFailure.validation, detail: detail),
      429 => const ApiException(ApiFailure.tooManyRequests),
      final int code when code >= 500 => const ApiException(ApiFailure.server),
      _ => ApiException(ApiFailure.unknown, detail: detail),
    };
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
