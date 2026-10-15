import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/history/history_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final type in ['ftth_bill', 'topup', 'wifi_package']) {
    test('fetches history for type $type', () async {
      final adapter = _HistoryAdapter('''
        {
          "data": [
            {
              "id": 17,
              "type": "$type",
              "description": "Matching history item",
              "amount": 2500,
              "transaction_no": "TXN-17",
              "created_at": "2026-10-14T09:00:00Z"
            },
            {
              "id": "other",
              "type": "unrelated",
              "description": "Unrelated history item",
              "created_at": "2026-10-13T09:00:00Z"
            }
          ]
        }
      ''');
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
        ..httpClientAdapter = adapter;

      final history = await HistoryRepository(dio).fetch(type: type);

      expect(adapter.request?.path, '/customer/transactions');
      expect(adapter.request?.queryParameters, {'type': type});
      expect(history, hasLength(1));
      expect(history.single.id, '17');
      expect(history.single.type, type);
      expect(history.single.description, 'Matching history item');
      expect(history.single.amount, 2500);
      expect(history.single.transactionNo, 'TXN-17');
      expect(history.single.createdAt, DateTime.utc(2026, 10, 14, 9));
    });
  }

  test('rejects an empty transaction type', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));

    await expectLater(
      HistoryRepository(dio).fetch(type: '  '),
      throwsArgumentError,
    );
  });

  test('fetches all transaction types when type is omitted', () async {
    final adapter = _HistoryAdapter('''
      {
        "data": [
          {
            "id": "topup-1",
            "type": "topup",
            "description": "Top-up",
            "created_at": "2026-10-14T09:00:00Z"
          },
          {
            "id": "bill-1",
            "type": "ftth_bill",
            "description": "Internet bill",
            "created_at": "2026-10-13T09:00:00Z"
          }
        ]
      }
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    final history = await HistoryRepository(dio).fetch();

    expect(adapter.request?.queryParameters, isEmpty);
    expect(history.map((item) => item.type), ['topup', 'ftth_bill']);
  });

  test('accepts a top-level list response', () async {
    final adapter = _HistoryAdapter('''
      [
        {
          "id": "bill-1",
          "type": "ftth_bill",
          "description": "Internet bill",
          "created_at": "2026-10-14T09:00:00Z"
        }
      ]
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    final history = await HistoryRepository(dio).fetch(type: 'ftth_bill');

    expect(history, hasLength(1));
    expect(history.single.id, 'bill-1');
  });

  test('rejects unsupported response shapes', () async {
    final adapter = _HistoryAdapter('{"message":"Unexpected response"}');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    await expectLater(
      HistoryRepository(dio).fetch(type: 'ftth_bill'),
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

class _HistoryAdapter implements HttpClientAdapter {
  _HistoryAdapter(this.body);

  final String body;
  RequestOptions? request;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
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
