import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/requests/change_wifi_password/change_wifi_password_repository.dart';
import 'package:cg_net_mobile/models/requests/change_password/change_password_model.dart';
import 'package:cg_net_mobile/pages/requests/change_wifi_password/change_wifi_password_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late ChangeWifiPasswordRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = _JsonAdapter();
    repository = ChangeWifiPasswordRepository(dio);
  });

  tearDown(() => dio.close());

  group('ChangePasswordRequestModel', () {
    test('fromJson parses change password request payload correctly', () {
      final json = {
        'id': '15',
        'user_id': 2,
        'broadband_account_number': 'CG0000011',
        'contact_name': 'Sophia',
        'contact_phone': '09757943906',
        'new_wifi_name': 'Home_WiFi',
        'ticket_number': 'CWP11030001',
        'new_password': 'secretpassword123',
        'status': 'under_review',
        'created_at': '2026-10-08T07:00:00.000Z',
      };

      final model = ChangePasswordRequestModel.fromJson(json);

      expect(model.id, '15');
      expect(model.userId, 2);
      expect(model.broadbandAccountNumber, 'CG0000011');
      expect(model.contactName, 'Sophia');
      expect(model.contactPhone, '09757943906');
      expect(model.newWifiName, 'Home_WiFi');
      expect(model.ticketNumber, 'CWP11030001');
      expect(model.newPassword, 'secretpassword123');
      expect(model.status, 'under_review');
    });

    test('toJson generates correct backend map', () {
      const model = ChangePasswordRequestModel(
        id: '15',
        userId: 2,
        broadbandAccountNumber: 'CG0000011',
        contactName: 'Sophia',
        contactPhone: '09757943906',
        newWifiName: 'Home_WiFi',
        newPassword: 'secretpassword123',
        status: 'under_review',
      );

      final json = model.toJson();

      expect(json['user_id'], 2);
      expect(json['broadband_account_number'], 'CG0000011');
      expect(json['contact_name'], 'Sophia');
      expect(json['contact_phone'], '09757943906');
      expect(json['new_wifi_name'], 'Home_WiFi');
      expect(json['new_password'], 'secretpassword123');
      expect(json['status'], 'under_review');
    });
  });

  group('ChangeWifiPasswordRepository', () {
    test('fetchRequests returns list of ChangePasswordRequestModel', () async {
      final items = await repository.fetchRequests();

      expect(items, hasLength(1));
      expect(items.first.broadbandAccountNumber, 'CG0000011');
      expect(items.first.status, 'under_review');
    });

    test('accepts a top-level list response', () async {
      _setResponse(dio, '''
        [
          {
            "id": "2",
            "user_id": 2,
            "broadband_account_number": "CG0000022",
            "contact_name": "Alexander",
            "contact_phone": "09757943907",
            "new_wifi_name": "Office_WiFi",
            "new_password": "password456",
            "status": "approved"
          }
        ]
      ''');

      final items = await repository.fetchRequests();

      expect(items, hasLength(1));
      expect(items.single.broadbandAccountNumber, 'CG0000022');
      expect(items.single.status, 'approved');
    });

    test('returns an empty list for an unsupported response shape', () async {
      _setResponse(dio, '{"data": "invalid"}');

      expect(await repository.fetchRequests(), isEmpty);
    });

    test('converts Dio server errors to ApiException', () async {
      _setResponse(dio, '{"message":"Server error"}', statusCode: 500);

      await expectLater(
        repository.fetchRequests(),
        throwsA(
          isA<ApiException>().having(
            (error) => error.failure,
            'failure',
            ApiFailure.server,
          ),
        ),
      );
    });

    test('submitRequest creates new change password request', () async {
      _setResponse(dio, '''
        {
          "code": "MSG-REQ-002",
          "id": "3",
          "user_id": 2,
          "broadband_account_number": "CG0000011",
          "contact_name": "Sophia",
          "contact_phone": "09757943906",
          "new_wifi_name": "New_WiFi",
          "new_password": "newpassword123",
          "status": "under_review"
        }
      ''');

      const model = ChangePasswordRequestModel(
        id: '',
        userId: 2,
        broadbandAccountNumber: 'CG0000011',
        contactName: 'Sophia',
        contactPhone: '09757943906',
        newWifiName: 'New_WiFi',
        newPassword: 'newpassword123',
      );

      final result = await repository.submitRequest(model);

      expect(result.request.id, '3');
      expect(result.request.broadbandAccountNumber, 'CG0000011');
      expect(result.code, 'MSG-REQ-002');
    });

    test('updateRequest updates an existing request', () async {
      _setResponse(dio, '''
        {
          "data": {
            "code": "MSG-REQ-003",
          "id": "15",
          "user_id": 2,
          "broadband_account_number": "CG0000011",
          "contact_name": "Sophia Updated",
          "contact_phone": "09757943906",
          "new_wifi_name": "Updated_WiFi",
          "ticket_number": "CWP11030001",
          "new_password": "updatedpassword123",
            "status": "under_review"
          }
        }
      ''');

      const request = ChangePasswordRequestModel(
        id: '15',
        userId: 2,
        broadbandAccountNumber: 'CG0000011',
        contactName: 'Sophia Updated',
        contactPhone: '09757943906',
        newWifiName: 'Updated_WiFi',
        newPassword: 'updatedpassword123',
        ticketNumber: 'CWP11030001',
      );

      final result = await repository.updateRequest(request);

      expect(result.request.id, '15');
      expect(result.request.contactName, 'Sophia Updated');
      expect(result.request.ticketNumber, 'CWP11030001');
      expect(result.code, 'MSG-REQ-003');
    });

    test('updateRequest sends null when the Wi-Fi name is cleared', () async {
      _setResponse(dio, '{"code":"MSG-REQ-003"}');

      const request = ChangePasswordRequestModel(
        id: '15',
        userId: 2,
        broadbandAccountNumber: 'CG0000011',
        contactName: 'Sophia',
        contactPhone: '09757943906',
        newWifiName: null,
        newPassword: 'updatedpassword123',
        ticketNumber: 'CWP11030001',
      );

      await repository.updateRequest(request);

      final payload =
          (dio.httpClientAdapter as _JsonAdapter).lastRequestOptions!.data
              as Map<String, dynamic>;
      expect(payload.containsKey('new_wifi_name'), isTrue);
      expect(payload['new_wifi_name'], isNull);
    });

    test('cancelRequest returns the backend message code', () async {
      _setResponse(dio, '{"code":"MSG-REQ-001","message":"Cancelled"}');

      const request = ChangePasswordRequestModel(
        id: '15',
        userId: 2,
        contactName: 'Sophia',
        contactPhone: '09757943906',
        newPassword: 'password123',
      );

      final result = await repository.cancelRequest(request);

      expect(result.code, 'MSG-REQ-001');
      final requestOptions =
          (dio.httpClientAdapter as _JsonAdapter).lastRequestOptions!;
      expect(requestOptions.method, 'PATCH');
      expect(
        requestOptions.uri.path,
        '/api/change-password-requests/15/cancel',
      );
    });
  });

  group('ChangeWifiPasswordController', () {
    test('prevents submission if an under_review request exists for same account', () async {
      final controller = ChangeWifiPasswordController(repository);
      addTearDown(controller.dispose);

      await controller.fetchRequests();

      final result = await controller.submitRequest(
        broadbandAccount: 'CG0000011',
        contactName: 'Sophia',
        contactPhone: '09757943906',
        newPassword: 'newpassword123',
      );

      expect(result, isNull);
      expect(controller.state.errorMessage, 'change_wifi.already_exists');
    });
  });
}

void _setResponse(
  Dio dio,
  String body, {
  int statusCode = 200,
}) {
  dio.httpClientAdapter = _JsonAdapter(body: body, statusCode: statusCode);
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter({
    String? body,
    this.statusCode = 200,
  }) : body = body ?? _defaultResponse;

  final String body;
  final int statusCode;
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
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

const _defaultResponse = '''
{
  "data": [
    {
      "id": "1",
      "user_id": 2,
      "broadband_account_number": "CG0000011",
      "contact_name": "Sophia",
      "contact_phone": "09757943906",
      "new_wifi_name": "Test_WiFi",
      "new_password": "password123",
      "status": "under_review"
    }
  ]
}
''';
