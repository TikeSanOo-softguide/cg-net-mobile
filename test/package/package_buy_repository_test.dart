import 'dart:typed_data';

import 'package:cg_net_mobile/data/package/package_buy_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buy sends product id, password, and idempotency header', () async {
    final adapter = _RecordingAdapter(
      '{"success":true,"data":{"transaction_no":"TXN-1"}}',
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = adapter;

    final result = await PackageBuyRepository(dio).buyPackage(
      productId: '249',
      password: '123456',
      idempotencyKey: 'pkg-key-0001',
    );

    expect(result.isSuccess, isTrue);
    expect(result.transactionNo, 'TXN-1');
    expect(adapter.path, '/packages/buy');
    expect(adapter.data, {
      'product_id': '249',
      'password': '123456',
    });
    expect(adapter.headers['Idempotency-Key'], 'pkg-key-0001');
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final String body;
  String? path;
  Object? data;
  Map<String, dynamic> headers = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    data = options.data;
    headers = options.headers;
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
