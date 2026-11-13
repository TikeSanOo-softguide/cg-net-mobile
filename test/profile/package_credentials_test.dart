import 'dart:typed_data';

import 'package:cg_net_mobile/core/storage/secure_storage/secure_storage.dart';
import 'package:cg_net_mobile/data/profile/profile_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('package credentials reads account and password', () async {
    final adapter = _RecordingAdapter(
      '{"data":{'
      '"customer_package_id":8,'
      '"starts_at":"2026-11-13T10:00:00.000000Z",'
      '"expires_at":"2026-12-13T10:00:00.000000Z",'
      '"package":{"product_name":"10M"},'
      '"credentials":{"account":"cg-249","password":"884422"}'
      '}}',
    );
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = adapter;

    final result =
        await ProfileRepository(dio, SecureStorage()).fetchPackageCredentials(18);

    expect(adapter.path, '/customer/packages/18/credentials');
    expect(result.account, 'cg-249');
    expect(result.password, '884422');
    expect(result.customerPackageId, 8);
    expect(result.productName, '10M');
    expect(result.expiresAt, isNotNull);
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final String body;
  String? path;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
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
