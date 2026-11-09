import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/message_codes.dart';
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

  test('serial check result exposes status separately from message', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"result":"already_used","message":"This top-up card has already been used."}',
        statusCode: 400,
      );

    final result = await TopUpRepository(dio).checkSerialNo('1234567890123456');

    expect(result.status, TopUpSerialCheckStatus.alreadyUsed);
    expect(result.message, 'This top-up card has already been used.');
  });

  test('top-up maps nested account-not-found response code', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"data":{"success":false,"code":"MSG-TOPUP-004"}}',
      );

    final result = await TopUpRepository(dio).topUpAccount(
      phone: '959123456789',
      pin: '1234567890123456',
      idempotencyKey: 'test-key',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, MessageCodes.topupAccountNotFound);
  });

  test('top-up HTTP 404 returns nested account-not-found result', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"data":{"code":"MSG-TOPUP-004"}}',
        statusCode: 404,
      );

    final result = await TopUpRepository(dio).topUpAccount(
      phone: '959123456789',
      pin: '1234567890123456',
      idempotencyKey: 'test-key',
    );

    expect(result.isSuccess, isFalse);
    expect(result.message, MessageCodes.topupAccountNotFound);
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
