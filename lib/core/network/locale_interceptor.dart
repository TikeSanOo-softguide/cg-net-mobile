import 'package:dio/dio.dart';

class LocaleInterceptor extends Interceptor {
  LocaleInterceptor(this._languageCode);

  final String Function() _languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final code = _languageCode();
    options.headers['Accept-Language'] = code.isEmpty ? 'en' : code;
    handler.next(options);
  }
}
