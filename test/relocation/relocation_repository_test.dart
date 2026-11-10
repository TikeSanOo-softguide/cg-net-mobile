import 'dart:async';
import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/data/requests/relocation/relocation_repository.dart';
import 'package:cg_net_mobile/models/requests/relocation/relocation_request_model.dart';
import 'package:cg_net_mobile/pages/requests/relocation/relocation_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('clears previous requests while fetching the current account list',
      () async {
    final dio = _dio(
      (_) => _jsonResponse(
        '{"data":[{"id":11,"user_id":8,"broadband_account_number":"BB-OLD",'
        '"current_address":"Old address","new_address":"New address",'
        '"contact_name":"Alex Example","phone":"09123456789"}]}',
      ),
    );
    final controller = RelocationController(RelocationRepository(dio));
    addTearDown(controller.dispose);

    await controller.fetchRequests();
    expect(controller.state.requests.single.broadbandAccountNumber, 'BB-OLD');

    final response = Completer<ResponseBody>();
    dio.httpClientAdapter = _AsyncResponseAdapter((_) => response.future);
    final fetch = controller.fetchRequests();

    expect(controller.state.status, RelocationStatus.loading);
    expect(controller.state.requests, isEmpty);

    response.complete(_jsonResponse('{"data":[]}'));
    await fetch;

    expect(controller.state.status, RelocationStatus.success);
    expect(controller.state.requests, isEmpty);
  });

  test('supports nullable broadband account, preferred date and details',
      () async {
    final model = RelocationRequestModel.fromJson({
      'id': 13,
      'user_id': 8,
      'broadband_account_number': null,
      'current_address': 'Old address',
      'new_address': 'New address',
      'preferred_date': null,
      'contact_name': 'Alex Example',
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
      'contact_name': 'Alex Example',
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
          '"preferred_date":"2026-12-01","contact_name":"Alex Example",'
          '"phone":"09123456789",'
          '"details":"Move upstairs","status":"under_review"}]}',
        );
      }
      if (options.method == 'POST') {
        return _jsonResponse(
          '{"code":"MSG-REQ-002","data":{"id":12,"user_id":8,"broadband_account_number":"BB-22",'
          '"current_address":"Old address","new_address":"New address",'
          '"preferred_date":"2026-12-01","contact_name":"Alex Example",'
          '"phone":"09123456789",'
          '"details":"Move upstairs","status":"under_review"}}',
        );
      }
      if (options.method == 'PUT') {
        return _jsonResponse(
          '{"code":"MSG-REQ-003","data":{"id":12,"user_id":8,"broadband_account_number":"BB-22",'
          '"current_address":"Old address","new_address":"New address",'
          '"preferred_date":"2026-12-01","contact_name":"Alex Example",'
          '"phone":"09123456789",'
          '"details":"Move upstairs","status":"under_review"}}',
        );
      }
      if (options.method == 'PATCH') {
        return _jsonResponse('{"code":"MSG-REQ-001"}');
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
      contactName: 'Alex Example',
      preferredDate: DateTime(2026, 12, 1),
      phone: '09123456789',
      details: 'Move upstairs',
    );

    final loaded = await repository.fetchRequests();
    final created = await repository.createRequest(request);
    final updated = await repository.updateRequest(created.request);
    final cancellationCode = await repository.cancelRequest(created.request.id);

    expect(loaded.single.id, '11');
    expect(loaded.single.preferredDate, DateTime(2026, 12, 1));
    expect(created.request.id, '12');
    expect(created.code, 'MSG-REQ-002');
    expect(updated.request.id, created.request.id);
    expect(updated.request.currentAddress, created.request.currentAddress);
    expect(updated.code, 'MSG-REQ-003');
    expect(cancellationCode, 'MSG-REQ-001');
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
        'contact_name': 'Alex Example',
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

class _AsyncResponseAdapter implements HttpClientAdapter {
  _AsyncResponseAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
