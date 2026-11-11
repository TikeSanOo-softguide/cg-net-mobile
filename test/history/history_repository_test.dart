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
              "note": "Matching history item",
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

  test('bill tab includes cg_bill with ftth_bill', () async {
    final adapter = _HistoryAdapter('''
      {
        "data": [
          {
            "id": "ftth-1",
            "type": "ftth_bill",
            "note": "FTTH bill",
            "created_at": "2026-10-14T09:00:00Z"
          },
          {
            "id": "cg-1",
            "type": "cg_bill",
            "note": "CG bill",
            "created_at": "2026-10-13T09:00:00Z"
          },
          {
            "id": "topup-1",
            "type": "topup",
            "note": "Top-up",
            "created_at": "2026-10-12T09:00:00Z"
          }
        ]
      }
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    final history = await HistoryRepository(dio).fetch(type: 'ftth_bill');

    expect(history.map((item) => item.type), ['ftth_bill', 'cg_bill']);
  });

  test('rejects an empty transaction type', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));

    await expectLater(
      HistoryRepository(dio).fetch(type: '  '),
      throwsArgumentError,
    );
  });

  test('service history uses /internet-bills/history', () async {
    final adapter = _HistoryAdapter('''
      {"data": [{"id": "1", "type": "topup", "created_at": "2026-10-14T09:00:00Z"}]}
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    await HistoryRepository(dio).fetchService();

    expect(adapter.request?.path, '/internet-bills/history');
  });

  test('maps ledger note when description is absent', () async {
    final adapter = _HistoryAdapter('''
      {
        "data": [
          {
            "id": 9,
            "type": "ftth_bill",
            "status": "completed",
            "amount": "1000.00",
            "note": "FTTH bill 10001234",
            "direction": "debit",
            "transaction_no": "PBFT1",
            "created_at": "2026-04-10 12:00:00"
          }
        ]
      }
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    final history = await HistoryRepository(dio).fetch();

    expect(history, hasLength(1));
    expect(history.single.description, 'FTTH bill 10001234');
    expect(history.single.amount, 1000);
    expect(history.single.isDebit, isTrue);
    expect(history.single.status, 'completed');
    expect(history.single.titleCode, '');
    expect(history.single.descriptionCode, '');
  });

  test('maps slim bill payment history from status', () async {
    final adapter = _HistoryAdapter('''
      {
        "data": [
          {
            "id": 9,
            "transaction_no": "PBFT1",
            "account": "10001234",
            "service_type": "FTTH",
            "amount": "1000.00",
            "status": "completed",
            "confirmed_at": "2026-04-10T12:00:00Z",
            "title_code": "MSG-FTTH-008",
            "description_code": "MSG-FTTH-008"
          }
        ]
      }
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    final history = await HistoryRepository(dio).fetchService();

    expect(adapter.request?.path, '/internet-bills/history');
    expect(history.single.type, 'ftth_bill');
    expect(history.single.isDebit, isTrue);
    expect(history.single.account, '10001234');
    expect(history.single.serviceType, 'FTTH');
    expect(history.single.titleCode, 'MSG-FTTH-008');
    expect(history.single.descriptionCode, 'MSG-FTTH-008');
    expect(history.single.createdAt, DateTime.utc(2026, 4, 10, 12));
  });

  test('fetches one bill payment from /internet-bills/history/{id}', () async {
    final adapter = _HistoryAdapter('''
      {
        "data": {
          "id": 9,
          "transaction_no": "PBFT1",
          "order_no": "FTTH-1",
          "account": "10001234",
          "service_type": "FTTH",
          "amount": "1000.00",
          "package": {"product_name": "FTTH 100M", "product_speed": "100M"},
          "remark": "Pay note",
          "status": "processing",
          "title_code": "MSG-FTTH-010",
          "description_code": "MSG-FTTH-010",
          "created_at": "2026-04-10T12:00:00Z",
          "confirmed_at": null
        }
      }
    ''');
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;

    final item = await HistoryRepository(dio).fetchServiceById('9');

    expect(adapter.request?.path, '/internet-bills/history/9');
    expect(item.id, '9');
    expect(item.account, '10001234');
    expect(item.description, 'Pay note');
    expect(item.remark, 'Pay note');
    expect(item.productName, 'FTTH 100M');
    expect(item.productSpeed, '100M');
    expect(item.orderNo, 'FTTH-1');
    expect(item.titleCode, 'MSG-FTTH-010');
    expect(item.descriptionCode, 'MSG-FTTH-010');
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
