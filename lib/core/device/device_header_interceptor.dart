import 'package:dio/dio.dart';

import 'device_identity.dart';

class DeviceHeaderInterceptor extends Interceptor {
  DeviceHeaderInterceptor(this.identity);

  final DeviceIdentity identity;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['User-Agent'] = identity.userAgent;
    options.headers['X-Device-Id'] = identity.id;
    options.headers['X-Device-Name'] = identity.name;
    options.headers['X-Platform'] = identity.platform;
    handler.next(options);
  }
}
