import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/data/requests/installation_application/installation_application_repository.dart';
import 'package:cg_net_mobile/models/requests/installation_application/installation_application_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses and serializes installation application fields', () {
    final model = InstallationApplicationModel.fromJson({
      'id': 13,
      'user_id': 8,
      'service_type': 'FTTH',
      'name': 'Applicant Name',
      'package_detail': {
        'product_id': '249',
        'product_name': '办公移动网_100M_月',
        'product_line': '移动网_办公',
        'product_speed': '100M',
        'product_price': 2000,
        'installation_fee': 500,
        'month_cycle': 1,
        'month_cycle_unit': '月',
      },
      'area_id': 2,
      'address': 'Installation address',
      'phone': '09123456789',
      'photos': [
        {'url': 'https://example.test/photo.jpg'},
      ],
      'note': null,
      'status': 'under_review',
      'created_at': '2026-10-19T10:00:00Z',
      'updated_at': '2026-10-19T10:00:00Z',
    });

    expect(model.id, '13');
    expect(model.serviceType, 'FTTH');
    expect(model.name, 'Applicant Name');
    expect(model.productId, '249');
    expect(model.productName, '办公移动网_100M_月');
    expect(model.packageDetail?['product_speed'], '100M');
    expect(model.areaId, 2);
    expect(model.photos, [
      {'url': 'https://example.test/photo.jpg'},
    ]);
    expect(model.toJson(), {
      'user_id': 8,
      'service_type': 'FTTH',
      'name': 'Applicant Name',
      'package_detail': {
        'product_id': '249',
        'product_name': '办公移动网_100M_月',
        'product_line': '移动网_办公',
        'product_speed': '100M',
        'product_price': 2000,
        'installation_fee': 500,
        'month_cycle': 1,
        'month_cycle_unit': '月',
      },
      'area_id': 2,
      'address': 'Installation address',
      'phone': '09123456789',
      'photos': [
        {'url': 'https://example.test/photo.jpg'},
      ],
      'note': null,
      'status': 'under_review',
    });
  });

  test('submits the installation payload without photos', () async {
    final requests = <RequestOptions>[];
    final repository = InstallationApplicationRepository(
      _dio((options) {
        requests.add(options);
        if (options.method == 'GET') {
          return _jsonResponse(
            '{"data":[{"id":11,"user_id":8,"name":"Applicant Name",'
            '"package_detail":{"product_id":"249","product_name":"100M"},'
            '"address":"Installation address",'
            '"phone":"09123456789","photos":[],"status":"under_review"}]}',
          );
        }
        if (options.method == 'POST') {
          return _jsonResponse(
            '{"code":"MSG-REQ-002","level":"success",'
            '"message":"Installation application submitted.",'
            '"data":{"id":12,"user_id":8,"name":"Applicant Name",'
            '"package_detail":{"product_id":"249","product_name":"100M"},'
            '"address":"Installation address",'
            '"phone":"09123456789","photos":[],"status":"under_review"}}',
          );
        }
        if (options.method == 'PUT') {
          return _jsonResponse(
            '{"code":"MSG-REQ-003","level":"success",'
            '"message":"Installation application updated.",'
            '"data":{"id":12,"status":"under_review"}}',
          );
        }
        if (options.method == 'PATCH') {
          return _jsonResponse(
            '{"code":"MSG-REQ-001","level":"success",'
            '"message":"Installation application cancelled.",'
            '"data":{"id":12,"status":"cancelled"}}',
          );
        }
        return _jsonResponse('{}');
      }),
    );
    const request = InstallationApplicationModel(
      id: '',
      userId: 8,
      serviceType: 'FTTH',
      productId: '249',
      productName: '办公移动网_100M_月',
      packageDetail: {
        'product_id': '249',
        'product_name': '办公移动网_100M_月',
        'product_line': '移动网_办公',
        'product_speed': '100M',
        'product_price': 2000,
        'installation_fee': 500,
        'month_cycle': 1,
        'month_cycle_unit': '月',
      },
      areaId: 2,
      name: 'Applicant Name',
      address: 'Installation address',
      phone: '09123456789',
      photos: [],
      note: null,
    );

    final loaded = await repository.fetchRequests();
    final created = await repository.createRequest(request);
    final updated = await repository.updateRequest(created.request);
    final code = await repository.cancelRequest(created.request.id);
    expect(code, 'MSG-REQ-001');
    expect(created.code, 'MSG-REQ-002');
    expect(updated.code, 'MSG-REQ-003');

    expect(loaded.single.id, '11');
    expect(created.request.id, '12');
    expect(updated.request.id, created.request.id);
    expect(
      requests.map((item) => (item.method, item.path)),
      [
        ('GET', ApiEndpoints.installationApplicationRequests),
        ('POST', ApiEndpoints.createInstallationApplicationRequest),
        ('PUT', ApiEndpoints.installationApplicationRequest('12')),
        ('PATCH', ApiEndpoints.cancelInstallationRequest('12')),
      ],
    );
    expect(requests[1].data, {
      'service_type': 'FTTH',
      'name': 'Applicant Name',
      'package_detail': {
        'product_id': '249',
        'product_name': '办公移动网_100M_月',
        'product_line': '移动网_办公',
        'product_speed': '100M',
        'product_price': 2000,
        'installation_fee': 500,
        'month_cycle': 1,
        'month_cycle_unit': '月',
      },
      'area_id': 2,
      'address': 'Installation address',
      'phone': '09123456789',
    });
  });

  test('loads FTTH products from Laravel installation-application/products', () async {
    final requests = <RequestOptions>[];
    final repository = InstallationApplicationRepository(
      _dio((options) {
        requests.add(options);
        return _jsonResponse(
          '{"data":[{"productID":"249","productName":"办公移动网_100M_月",'
          '"productPrice":2000.0,"monthCycle":1,"monthCycleUnit":"月",'
          '"productLine":"移动网_办公","productSpeed":"100M",'
          '"installationFee":500}]}',
        );
      }),
    );

    final options = await repository.fetchProducts('FTTH');

    expect(options.single.productId, '249');
    expect(options.single.productName, '办公移动网_100M_月');
    expect(options.single.productSpeed, '100M');
    expect(options.single.productLine, '移动网_办公');
    expect(options.single.productPrice, 2000);
    expect(options.single.installationFee, 500);
    expect(requests.single.path, ApiEndpoints.installationProducts);
    expect(requests.single.queryParameters['service_type'], 'FTTH');
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
    await requestStream?.drain<void>();
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
