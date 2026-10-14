import 'dart:typed_data';

import 'package:cg_net_mobile/data/top_up/top_up_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serial check treats HTTP 400 as invalid and keeps backend message',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"success":false,"message":"Invalid or unavailable top-up card."}',
        statusCode: 400,
      );

    final result = await TopUpRepository(dio).checkSerialNo('1234567890123456');

    expect(result.isValid, isFalse);
    expect(result.message, 'Invalid or unavailable top-up card.');
  });

  test('serial check treats HTTP 200 as valid without a success flag',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter =
          _JsonAdapter('{"message":"This top-up card is valid."}');

    final result = await TopUpRepository(dio).checkSerialNo('1234567890123456');

    expect(result.isValid, isTrue);
  });

  test('serial check treats HTTP 400 as invalid', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
          '{"message":"This top-up card is invalid."}',
          statusCode: 400);

    final result = await TopUpRepository(dio).checkSerialNo('1234567890123456');

    expect(result.isValid, isFalse);
  });
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
