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
      'product_id': '249',
      'product_name': '办公移动网_100M_月',
      'package_id': 4,
      'area_id': 2,
      'id_type': 'NRC',
      'id_name': 'Applicant Name',
      'id_number': 'ID-123',
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
    expect(model.productId, '249');
    expect(model.productName, '办公移动网_100M_月');
    expect(model.packageId, 4);
    expect(model.areaId, 2);
    expect(model.photos, [
      {'url': 'https://example.test/photo.jpg'},
    ]);
    expect(model.toJson(), {
      'user_id': 8,
      'service_type': 'FTTH',
      'product_id': '249',
      'product_name': '办公移动网_100M_月',
      'package_id': 4,
      'area_id': 2,
      'id_type': 'NRC',
      'id_name': 'Applicant Name',
      'id_number': 'ID-123',
      'address': 'Installation address',
      'phone': '09123456789',
      'photos': [
        {'url': 'https://example.test/photo.jpg'},
      ],
      'note': null,
      'status': 'under_review',
    });
  });

  test('submits the validated installation payload as multipart', () async {
    final requests = <RequestOptions>[];
    final repository = InstallationApplicationRepository(
      _dio((options) {
        requests.add(options);
        if (options.method == 'GET') {
          return _jsonResponse(
            '{"data":[{"id":11,"user_id":8,"package_id":4,'
            '"id_name":"Applicant Name",'
            '"address":"Installation address",'
            '"phone":"09123456789","photos":[],"status":"under_review"}]}',
          );
        }
        if (options.method == 'POST') {
          return _jsonResponse(
            '{"data":{"id":12,"user_id":8,"package_id":4,'
            '"id_name":"Applicant Name",'
            '"address":"Installation address",'
            '"phone":"09123456789","photos":[],"status":"under_review"}}',
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
      packageId: 4,
      areaId: 2,
      idType: '',
      idName: 'Applicant Name',
      idNumber: null,
      address: 'Installation address',
      phone: '09123456789',
      photos: [],
      note: null,
    );

    final loaded = await repository.fetchRequests();
    final created = await repository.createRequest(request);
    final updated = await repository.updateRequest(created);
    await repository.cancelRequest(created.id);

    expect(loaded.single.id, '11');
    expect(created.id, '12');
    expect(updated.id, created.id);
    expect(
      requests.map((item) => (item.method, item.path)),
      [
        ('GET', ApiEndpoints.installationApplicationRequests),
        ('POST', ApiEndpoints.createInstallationApplicationRequest),
        ('PUT', ApiEndpoints.installationApplicationRequest('12')),
        ('PATCH', ApiEndpoints.cancelInstallationRequest('12')),
      ],
    );
    final formData = requests[1].data as FormData;
    expect(
      Map.fromEntries(formData.fields),
      {
        'service_type': 'FTTH',
        'product_id': '249',
        'product_name': '办公移动网_100M_月',
        'area_id': '2',
        'id_name': 'Applicant Name',
        'address': 'Installation address',
        'phone': '09123456789',
      },
    );
    expect(formData.files, isEmpty);
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
