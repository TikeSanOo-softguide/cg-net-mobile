import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/core/network/auth_api/auth_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sends the selected language when registering and logging in', () async {
    final requests = <RequestOptions>[];
    final dio = _recordingDio(requests);
    final api = AuthApi(dio, () => 'my');

    await api.completeRegistration(
      verificationToken: 'verification-token',
      name: 'new_user',
      password: '123456',
    );
    await api.loginWithPassword(
      verificationToken: 'verification-token',
      password: '123456',
    );

    expect(requests[0].path, ApiEndpoints.completeRegistration);
    expect(requests[0].data['lang'], 'my');
    expect(requests[1].path, ApiEndpoints.login);
    expect(requests[1].data['lang'], 'my');
  });

  test('updates an existing user language using PATCH', () async {
    final requests = <RequestOptions>[];
    final api = AuthApi(_recordingDio(requests), () => 'en');

    await api.updateLanguage(lang: 'zh');

    expect(requests.single.method, 'PATCH');
    expect(requests.single.path, ApiEndpoints.language);
    expect(requests.single.data, {'lang': 'zh'});
  });
}

Dio _recordingDio(List<RequestOptions> requests) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {'token': 'test-token'},
          ),
        );
      },
    ),
  );
  return dio;
}
