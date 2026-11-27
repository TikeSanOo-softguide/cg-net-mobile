import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/network/auth_api/auth_api.dart';
import 'package:cg_net_mobile/core/network/message_codes.dart';
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
      deviceId: 'android:test-device',
    );
    await api.loginWithPassword(
      verificationToken: 'verification-token',
      password: '123456',
      deviceId: 'android:test-device',
    );

    expect(requests[0].path, ApiEndpoints.completeRegistration);
    expect(requests[0].data['lang'], 'my');
    expect(requests[0].data['device_id'], 'android:test-device');
    expect(requests[1].path, ApiEndpoints.login);
    expect(requests[1].data['lang'], 'my');
    expect(requests[1].data['device_id'], 'android:test-device');
  });

  test('updates an existing user language using PATCH', () async {
    final requests = <RequestOptions>[];
    final api = AuthApi(_recordingDio(requests), () => 'en');

    await api.updateLanguage(lang: 'zh');

    expect(requests.single.method, 'PATCH');
    expect(requests.single.path, ApiEndpoints.language);
    expect(requests.single.data, {'lang': 'zh'});
  });

  test('checks the phone session before requesting an OTP', () async {
    final requests = <RequestOptions>[];
    final api = AuthApi(
      _recordingDio(
        requests,
        responseData: {
          'show_alert': true,
        },
      ),
      () => 'en',
    );

    final result = await api.checkPhoneSession(
      '+959123456789',
      deviceId: 'android:test-device',
    );

    expect(requests.single.method, 'POST');
    expect(ApiEndpoints.checkSession, '/auth/session/check');
    expect(requests.single.uri.path, '/api/auth/session/check');
    expect(requests.single.data, {
      'phone': '+959123456789',
      'device_id': 'android:test-device',
    });
    expect(result.showAlert, isTrue);
    expect(result.deviceName, isNull);
  });

  test('reads the phone that already holds the session', () async {
    final api = AuthApi(
      _recordingDio(
        [],
        responseData: {
          'code': 'MSG-AUTH-012',
          'level': 'warning',
          'show_alert': true,
          'device_name': 'Samsung SM-A155F',
        },
      ),
      () => 'en',
    );

    final result = await api.checkPhoneSession(
      '+959123456789',
      deviceId: 'android:test-device',
    );

    expect(result.showAlert, isTrue);
    expect(result.deviceName, 'Samsung SM-A155F');
    expect(result.code, 'MSG-AUTH-012');
    expect(result.level, 'warning');
  });

  test('parses a phone session with no conflict', () async {
    final api = AuthApi(
      _recordingDio(
        [],
        responseData: {'show_alert': false},
      ),
      () => 'en',
    );

    final result = await api.checkPhoneSession(
      '+959123456789',
      deviceId: 'android:test-device',
    );
    expect(result.showAlert, isFalse);
    expect(result.showAlert, isFalse);
  });

  test('maps a 403 with the signed-in code to the existing warning', () async {
    final result = await _checkSession403({
      'code': MessageCodes.authAlreadySignedIn,
      'device_name': 'Samsung SM-A155F',
    });

    expect(result.showAlert, isTrue);
    expect(result.deviceName, 'Samsung SM-A155F');
    expect(result.code, MessageCodes.authAlreadySignedIn);
    expect(result.level, 'warning');
  });

  test('does not map an unrecognized 403 code to the signed-in warning',
      () async {
    await expectLater(
      _checkSession403({'code': MessageCodes.authRegistrationInUse}),
      throwsA(isA<ApiException>()),
    );
  });

  test('reads a session conflict code from the Laravel data envelope',
      () async {
    final result = await _checkSession403({
      'code': 'MSG-SYS-001',
      'data': {
        'code': MessageCodes.authAlreadySignedIn,
        'device_name': 'Samsung SM-A155F',
      },
    });

    expect(result.showAlert, isTrue);
    expect(result.deviceName, 'Samsung SM-A155F');
  });
}

Future<AccountSessionCheckResult> _checkSession403(
  Map<String, dynamic> responseData,
) async {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response<dynamic>(
              requestOptions: options,
              statusCode: 403,
              data: responseData,
            ),
            type: DioExceptionType.badResponse,
          ),
        );
      },
    ),
  );
  final api = AuthApi(dio, () => 'en');

  return api.checkPhoneSession(
    '+959123456789',
    deviceId: 'android:other-device',
  );
}

Dio _recordingDio(
  List<RequestOptions> requests, {
  Map<String, dynamic> responseData = const {'token': 'test-token'},
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        requests.add(options);
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: responseData,
          ),
        );
      },
    ),
  );
  return dio;
}
