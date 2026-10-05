import 'package:dio/dio.dart';

class GetRetryInterceptor extends Interceptor {
  GetRetryInterceptor(this._dio);

  final Dio _dio;
  static const _maxAttempts = 2;

  /// Set to `true` in `Options.extra` to fail fast instead of retrying.
  static const skipKey = 'skip_retry';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final attempts = request.extra['retry_attempt'] as int? ?? 0;
    if (!_canRetry(request, err, attempts)) {
      handler.next(err);
      return;
    }

    request.extra['retry_attempt'] = attempts + 1;
    try {
      final response = await _dio.fetch<dynamic>(request);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _canRetry(RequestOptions request, DioException error, int attempts) {
    if (request.method.toUpperCase() != 'GET') return false;
    if (request.extra[skipKey] == true) return false;
    if (attempts >= _maxAttempts) return false;
    if (CancelToken.isCancel(error)) return false;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }
}
