import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/change_password/change_password_repository.dart';
import 'package:cg_net_mobile/models/change_password_model/change_password_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const password = ChangePasswordModel(
    currentPassword: '123456',
    newPassword: '654321',
    newPasswordConfirmation: '654321',
  );

  test('requests password change and parses OTP challenge details', () async {
    final adapter = _TestAdapter([
      const _StubResponse(
        statusCode: 202,
        body:
            '{"challenge_id":"challenge-1","debug_otp":"135790","resend_after":45}',
      ),
    ]);
    final repository = ChangePasswordRepository(_createDio(adapter));

    final challenge = await repository.changePassword(password: password);

    expect(challenge.challengeId, 'challenge-1');
    expect(challenge.debugOtp, '135790');
    expect(challenge.resendAfter, 45);
    expect(adapter.requests.single.path, '/change-password');
    expect(adapter.requests.single.data, password.toJson());
  });

  test('uses 60 seconds when resend delay is missing or invalid', () async {
    final adapter = _TestAdapter([
      const _StubResponse(
        statusCode: 202,
        body: '{"challenge_id":"challenge-1","resend_after":0}',
      ),
    ]);
    final repository = ChangePasswordRepository(_createDio(adapter));

    final challenge = await repository.changePassword(password: password);

    expect(challenge.resendAfter, 60);
  });

  test('verifies OTP with challenge_id and code fields', () async {
    final adapter = _TestAdapter([
      const _StubResponse(statusCode: 200, body: '{"message":"Verified"}'),
    ]);
    final repository = ChangePasswordRepository(_createDio(adapter));

    await repository.verifyOtp(
      challengeId: 'challenge-1',
      otp: '135790',
    );

    expect(adapter.requests.single.path, '/change-password/verify-otp');
    expect(adapter.requests.single.data, {
      'challenge_id': 'challenge-1',
      'code': '135790',
    });
  });

  test('maps invalid current-password response to validation failure',
      () async {
    final adapter = _TestAdapter([
      const _StubResponse(
        statusCode: 422,
        body:
            '{"message":"The password is incorrect.","errors":{"current_password":["The password is incorrect."]}}',
      ),
    ]);
    final repository = ChangePasswordRepository(_createDio(adapter));

    await expectLater(
      repository.changePassword(password: password),
      throwsA(
        isA<ApiException>()
            .having((error) => error.failure, 'failure', ApiFailure.validation)
            .having(
              (error) => error.detail,
              'detail',
              'The password is incorrect.',
            )
            .having((error) => error.statusCode, 'status code', 422),
      ),
    );
  });

  test('uses retry_after from rate-limit response', () async {
    final adapter = _TestAdapter([
      const _StubResponse(
        statusCode: 429,
        body: '{"message":"Please wait before trying again.","retry_after":37}',
      ),
    ]);
    final repository = ChangePasswordRepository(_createDio(adapter));

    await expectLater(
      repository.changePassword(password: password),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.failure,
              'failure',
              ApiFailure.tooManyRequests,
            )
            .having((error) => error.detail, 'retry-after detail', '37')
            .having((error) => error.statusCode, 'status code', 429),
      ),
    );
  });

  test('rejects challenge responses that do not include a challenge ID',
      () async {
    final adapter = _TestAdapter([
      const _StubResponse(statusCode: 202, body: '{"debug_otp":"135790"}'),
    ]);
    final repository = ChangePasswordRepository(_createDio(adapter));

    await expectLater(
      repository.changePassword(password: password),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.unknown,
        ),
      ),
    );
  });
}

Dio _createDio(_TestAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'http://example.test/api'))
    ..httpClientAdapter = adapter;
}

class _StubResponse {
  const _StubResponse({
    required this.statusCode,
    required this.body,
  }) : headers = const {};

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
}

class _TestAdapter implements HttpClientAdapter {
  _TestAdapter(this._responses);

  final List<_StubResponse> _responses;
  final requests = <RequestOptions>[];
  var _responseIndex = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final response = _responses[_responseIndex++];
    return ResponseBody.fromString(
      response.body,
      response.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...response.headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
