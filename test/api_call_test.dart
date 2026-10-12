import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/network/idempotency_key.dart';
import 'package:cg_net_mobile/data/inbox/inbox_repository.dart';
import 'package:cg_net_mobile/data/top_up/top_up_repository.dart';
import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:cg_net_mobile/pages/home/top_up/top_up_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('idempotency keys are opaque UUIDs', () {
    final first = IdempotencyKey.generate();
    final second = IdempotencyKey.generate();

    expect(first, matches(_uuidV4Pattern));
    expect(second, isNot(first));
  });

  test('top-up retries reuse the key after a connection error', () async {
    final adapter = _RetryTopUpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = adapter;
    final controller = TopUpController(TopUpRepository(dio));
    addTearDown(controller.dispose);

    await expectLater(
      controller.submit(phone: '959123456789', pin: '1234567890123456'),
      throwsA(isA<ApiException>()),
    );
    await controller.submit(
      phone: '959123456789',
      pin: '1234567890123456',
    );

    expect(adapter.idempotencyKeys, hasLength(2));
    expect(adapter.idempotencyKeys[0], adapter.idempotencyKeys[1]);
  });

  test('connection errors become offline failures', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/inbox'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(error.failure, ApiFailure.offline);
    expect(error.messageKey, 'api.offline');
  });

  test('validation errors keep the first field message', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/auth/otp/request'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/otp/request'),
          statusCode: 422,
          data: {
            'message': 'The phone field is invalid.',
            'errors': {
              'phone': ['The phone field is invalid.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error.failure, ApiFailure.validation);
    expect(error.detail, 'The phone field is invalid.');
    expect(error.statusCode, 422);
    expect(error.responseData, {
      'message': 'The phone field is invalid.',
      'errors': {
        'phone': ['The phone field is invalid.'],
      },
    });
  });

  test('bad request errors retain the backend response', () {
    final responseData = {'message': 'PIN must not exceed 16 digits.'};
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/top-up'),
        response: Response(
          requestOptions: RequestOptions(path: '/top-up'),
          statusCode: 400,
          data: responseData,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error.failure, ApiFailure.unknown);
    expect(error.statusCode, 400);
    expect(error.detail, 'PIN must not exceed 16 digits.');
    expect(error.responseData, responseData);
  });

  test('inbox repository reads the data list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));
    dio.httpClientAdapter = _JsonAdapter('''
      {"data":[{"id":"announcement-1","category":"announcement","title":{"en":"Hello","my":"မင်္ဂလာပါ","zh":"你好"},"body":{"en":"Body","my":"စာ","zh":"内容"},"created_at":"2026-10-02T09:00:00.000000Z","is_read":false}]}
    ''');

    final items = await InboxRepository(dio).fetch();

    expect(items, hasLength(1));
    expect(items.single.category, InboxCategory.announcement);
    expect(items.single.titleFor('my'), 'မင်္ဂလာပါ');
  });

  test('serial check keeps the backend response message', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"success":false,"message":"Invalid or unavailable top-up card."}',
      );

    final result = await TopUpRepository(dio).checkSerialNo('1234567890123456');

    expect(result.isValid, isFalse);
    expect(result.message, 'Invalid or unavailable top-up card.');
  });
}

final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body);

  final String body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RetryTopUpAdapter implements HttpClientAdapter {
  final idempotencyKeys = <String?>[];
  var _attempt = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    idempotencyKeys.add(options.headers['Idempotency-Key'] as String?);
    if (_attempt++ == 0) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }

    return ResponseBody.fromString(
      '{"success":true,"message":"Top-up successful."}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
