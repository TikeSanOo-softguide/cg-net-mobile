import 'package:cg_net_mobile/core/device/device_header_interceptor.dart';
import 'package:cg_net_mobile/core/device/device_identity.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds a user agent that includes the phone name', () {
    final identity = DeviceIdentity(
      id: '8f3c1b2a-4d5e-4f60-8a71-223344556677',
      name: 'Samsung SM-A155F',
      platform: 'android',
      appVersion: '1.0.0',
    );

    expect(
      identity.userAgent,
      'cg-net-mobile/1.0.0 (android; Samsung SM-A155F)',
    );
    expect(identity.name, 'Samsung SM-A155F');
    expect(identity.platform, 'android');
  });

  test('drops characters that cannot travel in a header', () {
    final identity = DeviceIdentity(
      id: 'not an id',
      name: "Samsung\nSM-A155F",
      platform: 'Android',
      appVersion: '1.0.0',
    );

    expect(identity.id, isNot('not an id'));
    expect(DeviceIdentity.isDeviceId(identity.id), isTrue);
    expect(identity.name, 'Samsung SM-A155F');
    expect(identity.platform, 'android');
  });

  test('sends the phone on every request', () async {
    final identity = DeviceIdentity(
      id: '8f3c1b2a-4d5e-4f60-8a71-223344556677',
      name: 'Samsung SM-A155F',
      platform: 'ios',
      appVersion: '1.0.0',
    );
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(DeviceHeaderInterceptor(identity));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: const {'ok': true},
            ),
          );
        },
      ),
    );

    await dio.post<dynamic>('/auth/login', data: {'password': '123456'});

    expect(
      requests.single.headers['User-Agent'],
      'cg-net-mobile/1.0.0 (ios; Samsung SM-A155F)',
    );
    expect(
      requests.single.headers['X-Device-Id'],
      '8f3c1b2a-4d5e-4f60-8a71-223344556677',
    );
    expect(requests.single.headers['X-Device-Name'], 'Samsung SM-A155F');
    expect(requests.single.headers['X-Platform'], 'ios');
  });
}
