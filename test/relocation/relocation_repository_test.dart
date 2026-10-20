import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/data/requests/relocation/relocation_repository.dart';
import 'package:cg_net_mobile/models/requests/relocation/relocation_request_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('supports nullable broadband account, preferred date and details',
      () async {
    final model = RelocationRequestModel.fromJson({
      'id': 13,
      'user_id': 8,
      'broadband_account_number': null,
      'current_address': 'Old address',
      'new_address': 'New address',
      'preferred_date': null,
      'phone': '09123456789',
      'details': null,
      'status': 'under_review',
      'created_at': '2026-10-19T10:00:00Z',
      'updated_at': '2026-10-19T10:00:00Z',
    });

    expect(model.broadbandAccountNumber, isNull);
    expect(model.preferredDate, isNull);
    expect(model.details, isNull);
    expect(model.toJson(), {
      'user_id': 8,
      'broadband_account_number': null,
      'current_address': 'Old address',
      'new_address': 'New address',
      'preferred_date': null,
      'phone': '09123456789',
      'details': null,
      'status': 'under_review',
    });
  });

  test('uses the relocation API routes and request payload', () async {
    final requests = <RequestOptions>[];
    final dio = _dio((options) {
      requests.add(options);
      if (options.method == 'GET') {
        return _jsonResponse(
          '{"data":[{"id":11,"user_id":8,"broadband_account_number":"BB-22",'
          '"current_address":"Old address","new_address":"New address",'
          '"preferred_date":"2026-12-01","phone":"09123456789",'
          '"details":"Move upstairs","status":"under_review"}]}',
        );
      }
      if (options.method == 'POST') {
        return _jsonResponse(
          '{"data":{"id":12,"user_id":8,"broadband_account_number":"BB-22",'
          '"current_address":"Old address","new_address":"New address",'
          '"preferred_date":"2026-12-01","phone":"09123456789",'
          '"details":"Move upstairs","status":"under_review"}}',
        );
      }
      return _jsonResponse('{}');
    });
    final repository = RelocationRepository(dio);
    final request = RelocationRequestModel(
      id: '',
      userId: 8,
      broadbandAccountNumber: 'BB-22',
      currentAddress: 'Old address',
      newAddress: 'New address',
      preferredDate: DateTime(2026, 12, 1),
      phone: '09123456789',
      details: 'Move upstairs',
    );

    final loaded = await repository.fetchRequests();
    final created = await repository.createRequest(request);
    final updated = await repository.updateRequest(created);
    await repository.cancelRequest(created.id);

    expect(loaded.single.id, '11');
    expect(loaded.single.preferredDate, DateTime(2026, 12, 1));
    expect(created.id, '12');
    expect(updated.id, created.id);
    expect(updated.currentAddress, created.currentAddress);
    expect(
      requests.map((item) => (item.method, item.path)),
      [
        ('GET', ApiEndpoints.relocationRequests),
        ('POST', ApiEndpoints.createRelocationRequest),
        ('PUT', ApiEndpoints.relocationRequest('12')),
        ('PATCH', ApiEndpoints.cancelRelocationRequest('12')),
      ],
    );
    expect(
      requests[1].data,
      {
        'user_id': 8,
        'broadband_account_number': 'BB-22',
        'current_address': 'Old address',
        'new_address': 'New address',
        'preferred_date': '2026-12-01',
        'phone': '09123456789',
        'details': 'Move upstairs',
        'status': 'under_review',
      },
    );
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
