import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/inbox/inbox_repository.dart';
import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        requestOptions: RequestOptions(path: '/auth/register/request-otp'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/register/request-otp'),
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
}

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
