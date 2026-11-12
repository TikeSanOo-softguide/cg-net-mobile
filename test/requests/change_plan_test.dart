import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/data/requests/change_plan/change_plan_repository.dart';
import 'package:cg_net_mobile/models/requests/change_plan/change_plan_request_model.dart';
import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('current package details include monthly term fields', () {
    final profile = UserProfileModel.fromJson({
      'data': {
        'account': {'productName': 'CG-NET_20M_月'},
      },
    });

    expect(
      ChangePlanRequestModel.currentDetailFrom(profile)['term'],
      {'months': 1, 'cycle': 1, 'cycle_unit': '月'},
    );
  });

  test('current package details preserve non-month cycle units', () {
    final profile = UserProfileModel.fromJson({
      'data': {
        'account': {'productName': 'CG-NET_20M'},
        'packages': [
          {
            'package_id': 3,
            'details': {
              'term': {'cycle': 7, 'cycle_unit': '天'},
            },
          },
        ],
      },
    });

    expect(
      ChangePlanRequestModel.currentDetailFrom(profile)['term'],
      {'cycle': 7, 'cycle_unit': '天'},
    );
  });

  test('fetchRequests preserves paginated API order across statuses',
      () async {
    final requests = <RequestOptions>[];
    final repository = ChangePlanRepository(
      _dio((options) {
        requests.add(options);
        return _jsonResponse('''
          {
            "data": {
              "current_page": 1,
              "data": [
                {
                  "id": 16,
                  "user_id": 2,
                  "status": "approved",
                  "created_at": "2026-11-01T10:00:00Z"
                },
                {
                  "id": 15,
                  "user_id": 2,
                  "status": "cancelled",
                  "created_at": "2026-10-01T10:00:00Z"
                }
              ]
            }
          }
        ''');
      }),
    );

    final records = await repository.fetchRequests();

    expect(records.map((record) => record.id), ['16', '15']);
    expect(records.map((record) => record.status), ['approved', 'cancelled']);
    expect(requests.single.uri.path, endsWith(ApiEndpoints.changePlanRequests));
  });

  test('cancelRequest uses the cancel action and returns its message code',
      () async {
    late RequestOptions request;
    final repository = ChangePlanRepository(
      _dio((options) {
        request = options;
        return _jsonResponse('{"data":{"code":"MSG-REQ-001"}}');
      }),
    );

    final code = await repository.cancelRequest('15');

    expect(code, 'MSG-REQ-001');
    expect(request.method, 'PATCH');
    expect(
      request.uri.path,
      endsWith(ApiEndpoints.cancelChangePlanRequest('15')),
    );
  });

  test('updateRequest uses the request resource and keeps the existing id',
      () async {
    late RequestOptions requestOptions;
    final repository = ChangePlanRepository(
      _dio((options) {
        requestOptions = options;
        return _jsonResponse(
          '{"data":{"id":15,"user_id":2,"status":"under_review"}}',
        );
      }),
    );

    final result = await repository.updateRequest(
      const ChangePlanRequestModel(
        id: '15',
        userId: 2,
        contactName: 'Customer',
        contactPhone: '09123456789',
      ),
    );

    expect(result.request.id, '15');
    expect(requestOptions.method, 'PUT');
    expect(
      requestOptions.uri.path,
      endsWith(ApiEndpoints.changePlanRequest('15')),
    );
    expect((requestOptions.data as Map)['user_id'], 2);
  });
}

Dio _dio(ResponseBody Function(RequestOptions options) respond) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'));
  dio.httpClientAdapter = _ResponseAdapter(respond);
  return dio;
}

ResponseBody _jsonResponse(String body) {
  return ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
