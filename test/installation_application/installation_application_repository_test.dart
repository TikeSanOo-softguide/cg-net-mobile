import 'dart:io';
import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/requests/installation_application/installation_application_repository.dart';
import 'package:cg_net_mobile/models/requests/installation_application/installation_application_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  test('parses and serializes installation application fields', () {
    final model = InstallationApplicationModel.fromJson({
      'id': 13,
      'user_id': 8,
      'service_type': 'FTTH',
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
    expect(model.packageId, 4);
    expect(model.areaId, 2);
    expect(model.photos, [
      {'url': 'https://example.test/photo.jpg'},
    ]);
    expect(model.toJson(), {
      'user_id': 8,
      'service_type': 'FTTH',
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
    final tempDirectory = await Directory.systemTemp.createTemp();
    final firstPhoto = File('${tempDirectory.path}\\front.jpg');
    final secondPhoto = File('${tempDirectory.path}\\back.png');
    await firstPhoto.writeAsBytes([1, 2, 3]);
    await secondPhoto.writeAsBytes([4, 5, 6]);

    final requests = <RequestOptions>[];
    final repository = InstallationApplicationRepository(
      _dio((options) {
        requests.add(options);
        if (options.method == 'GET') {
          return _jsonResponse(
            '{"data":[{"id":11,"user_id":8,"package_id":4,"area_id":2,'
            '"id_type":"NRC","id_name":"Applicant Name",'
            '"id_number":"ID-123","address":"Installation address",'
            '"phone":"09123456789","photos":[],"status":"under_review"}]}',
          );
        }
        if (options.method == 'POST') {
          return _jsonResponse(
            '{"data":{"id":12,"user_id":8,"package_id":4,"area_id":2,'
            '"id_type":"NRC","id_name":"Applicant Name",'
            '"id_number":"ID-123","address":"Installation address",'
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
      packageId: 4,
      areaId: 2,
      idType: 'NRC',
      idName: 'Applicant Name',
      idNumber: 'ID-123',
      address: 'Installation address',
      phone: '09123456789',
      photos: [],
      note: null,
    );

    final loaded = await repository.fetchRequests();
    final created = await repository.createRequest(
      request,
      photos: [
        XFile(firstPhoto.path),
        XFile(secondPhoto.path),
      ],
    );
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
        'package_id': '4',
        'area_id': '2',
        'id_type': 'NRC',
        'id_name': 'Applicant Name',
        'id_number': 'ID-123',
        'address': 'Installation address',
        'phone': '09123456789',
      },
    );
    expect(
      formData.files.map((entry) => entry.key),
      ['photos[0]', 'photos[1]'],
    );
    expect(formData.files.map((entry) => entry.value.filename), [
      'front.jpg',
      'back.png',
    ]);
    await tempDirectory.delete(recursive: true);
  });

  test('rejects creation unless exactly two photos are provided', () async {
    final repository = InstallationApplicationRepository(
      _dio((_) => _jsonResponse('{}')),
    );
    const request = InstallationApplicationModel(
      id: '',
      userId: 8,
      serviceType: 'FTTH',
      packageId: 4,
      areaId: 2,
      idType: 'NRC',
      idName: 'Applicant Name',
      idNumber: 'ID-123',
      address: 'Installation address',
      phone: '09123456789',
      photos: [],
      note: null,
    );

    await expectLater(
      repository.createRequest(request, photos: []),
      throwsA(isA<ApiException>()),
    );
  });

  test('rejects unsupported and oversized photos before sending the request',
      () async {
    final tempDirectory = await Directory.systemTemp.createTemp();
    addTearDown(() => tempDirectory.delete(recursive: true));
    final validPhoto = File('${tempDirectory.path}\\valid.jpg');
    final unsupportedPhoto = File('${tempDirectory.path}\\document.gif');
    final oversizedPhoto = File('${tempDirectory.path}\\oversized.jpg');
    await validPhoto.writeAsBytes([1, 2, 3]);
    await unsupportedPhoto.writeAsBytes([1, 2, 3]);
    await oversizedPhoto.writeAsBytes(
      List<int>.filled(2 * 1024 * 1024 + 1, 0),
    );

    final repository = InstallationApplicationRepository(
      _dio((_) => _jsonResponse('{}')),
    );
    const request = InstallationApplicationModel(
      id: '',
      userId: 8,
      serviceType: 'FTTH',
      packageId: 4,
      areaId: 2,
      idType: 'NRC',
      idName: 'Applicant Name',
      idNumber: 'ID-123',
      address: 'Installation address',
      phone: '09123456789',
      photos: [],
      note: null,
    );

    await expectLater(
      repository.createRequest(
        request,
        photos: [
          XFile(unsupportedPhoto.path),
          XFile(oversizedPhoto.path),
        ],
      ),
      throwsA(isA<ApiException>()),
    );
    await expectLater(
      repository.createRequest(
        request,
        photos: [
          XFile(validPhoto.path),
          XFile(oversizedPhoto.path),
        ],
      ),
      throwsA(isA<ApiException>()),
    );
  });

  test('loads active packages and areas from the option endpoints', () async {
    final requests = <RequestOptions>[];
    final repository = InstallationApplicationRepository(
      _dio((options) {
        requests.add(options);
        if (options.path == ApiEndpoints.availablePlans) {
          return _jsonResponse(
            '{"data":[{"id":4,"name":{"en":"Home Plan","my":"အိမ်သုံး"},'
            '"is_active":true},{"id":5,"name":"Inactive","is_active":false}]}',
          );
        }
        return _jsonResponse(
          '{"data":[{"id":2,"name":{"en":"Central Area","my":"မြို့လယ်"}}]}',
        );
      }),
    );

    final options = await repository.fetchRequestOptions();

    expect(options.packages.map((option) => option.id), [4]);
    expect(options.packages.single.serviceType, isNull);
    expect(options.packages.single.localizedName('my'), 'အိမ်သုံး');
    expect(options.areas.single.id, 2);
    expect(options.areas.single.localizedName('en'), 'Central Area');
    expect(
      requests.map((request) => request.path).toSet(),
      {ApiEndpoints.availablePlans, ApiEndpoints.availableAreas},
    );
  });

  test('infers package service type from network names', () {
    final ftth = InstallationApplicationOption.fromJson({
      'id': 4,
      'service_type': 'FTTH',
      'network': {
        'name': {'en': 'CG FTTH'},
      },
    });
    final cg = InstallationApplicationOption.fromJson({
      'id': 5,
      'network': {
        'name': {'en': 'CG Wireless'},
      },
    });

    expect(ftth.serviceType, 'FTTH');
    expect(cg.serviceType, 'CG');
    expect(ftth.matchesServiceType('FTTH'), isTrue);
    expect(ftth.matchesServiceType('CG'), isFalse);
    expect(cg.matchesServiceType('CG'), isTrue);
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
