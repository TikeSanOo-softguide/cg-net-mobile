import 'dart:io';
import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/requests/complaint/complaint_repository.dart';
import 'package:cg_net_mobile/models/requests/complaint/complaint_model.dart';
import 'package:cg_net_mobile/pages/requests/complaint/complaint_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late ComplaintRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = _JsonAdapter();
    repository = ComplaintRepository(dio);
  });

  tearDown(() => dio.close());

  group('ComplaintRepository', () {
    test('fetchComplaints reads records from a paginated data envelope',
        () async {
      _setResponse(dio, '''
        {
          "data": {
            "current_page": 1,
            "data": [
              {
                "id": 15,
                "user_id": 2,
                "failure_type": "no_internet",
                "description": "No connection",
                "contact_name": "Sophia",
                "contact_phone": "09757943906",
                "ticket_number": "FLR-2026-0015",
                "status": "under_review",
                "photos": [
                  {
                    "id": 42,
                    "failure_report_id": 15,
                    "image_url": "https://example.test/report-photo.jpg"
                  }
                ]
              }
            ]
          }
        }
      ''');

      final reports = await repository.fetchComplaints();

      expect(reports, hasLength(1));
      expect(reports.single.id, '15');
      expect(reports.single.status, 'under_review');
      expect(reports.single.contactName, 'Sophia');
      expect(reports.single.ticketNumber, 'FLR-2026-0015');
      expect(reports.single.photos, hasLength(1));
      expect(
        reports.single.photos.single.imageUrl,
        'https://example.test/report-photo.jpg',
      );
    });

    test('fetchComplaints returns approved reports for history', () async {
      _setResponse(dio, '''
        {
          "data": [
            {
              "id": 16,
              "user_id": 2,
              "failure_type": "slow",
              "description": "Speed is back to normal",
              "contact_name": "Moe Moe",
              "contact_phone": "09770000002",
              "status": "approved"
            }
          ]
        }
      ''');

      final reports = await repository.fetchComplaints();

      expect(reports, hasLength(1));
      expect(reports.single.id, '16');
      expect(reports.single.status, 'approved');
    });

    test('fetchComplaint loads photo URLs from the detail endpoint', () async {
      _setResponse(dio, '''
        {
          "data": {
            "id": 17,
            "user_id": 3,
            "failure_type": "equipment",
            "description": "Router is damaged",
            "contact_name": "Aye Aye",
            "contact_phone": "09770000001",
            "ticket_number": "FLR-2026-0017",
            "status": "under_review",
            "photos": [
              {
                "id": 51,
                "failure_report_id": 17,
                "image_url": "https://example.test/storage/report.jpg"
              }
            ]
          }
        }
      ''');

      final report = await repository.fetchComplaint('17');

      expect(report.id, '17');
      expect(report.ticketNumber, 'FLR-2026-0017');
      expect(report.photos, hasLength(1));
      expect(
        report.photos.single.imageUrl,
        'https://example.test/storage/report.jpg',
      );
    });

    test('fetchComplaint resolves relative photo storage paths', () async {
      _setResponse(dio, '''
        {
          "data": {
            "id": 18,
            "user_id": 3,
            "failure_type": "equipment",
            "description": "Router is damaged",
            "contact_name": "Aye Aye",
            "contact_phone": "09770000001",
            "status": "under_review",
            "photos": [
              {
                "id": 52,
                "failure_report_id": 18,
                "image_url": "/storage/failure-reports/report.jpg"
              }
            ]
          }
        }
      ''');

      final report = await repository.fetchComplaint('18');
      final origin = Uri.parse(ApiEndpoints.baseUrl).origin;

      expect(
        report.photos.single.imageUrl,
        '$origin/storage/failure-reports/report.jpg',
      );
    });

    test('updateComplaint sends text-only edits with PUT', () async {
      final adapter = _JsonAdapter();
      dio.httpClientAdapter = adapter;

      await repository.updateComplaint(
        const ComplaintModel(
          id: '19',
          userId: 3,
          complaintType: 'equipment',
          description: 'Updated description',
          contactName: 'Aye Aye',
          contactPhone: '09770000001',
        ),
      );

      expect(adapter.lastRequestOptions?.method, 'PUT');
      expect(
        adapter.lastRequestOptions?.uri.path,
        endsWith('/failure-reports/19'),
      );
    });

    test('create, update, and cancel preserve backend message codes', () async {
      const report = ComplaintModel(
        id: '22',
        userId: 3,
        complaintType: 'equipment',
        description: 'Router is damaged',
        contactName: 'Aye Aye',
        contactPhone: '09770000001',
      );
      final responseReport = '''
        {
          "id": 22,
          "user_id": 3,
          "failure_type": "equipment",
          "description": "Router is damaged",
          "contact_name": "Aye Aye",
          "contact_phone": "09770000001"
        }
      ''';

      _setResponse(
        dio,
        '{"code":"MSG-REQ-002","data":$responseReport}',
      );
      final created = await repository.submitComplaint(report);
      expect(created.code, 'MSG-REQ-002');

      _setResponse(
        dio,
        '''
        {
          "data": {
            "code": "MSG-REQ-003",
            "id": 22,
            "user_id": 3,
            "failure_type": "equipment",
            "description": "Router is damaged",
            "contact_name": "Aye Aye",
            "contact_phone": "09770000001"
          }
        }
        ''',
      );
      final updated = await repository.updateComplaint(report);
      expect(updated.code, 'MSG-REQ-003');

      _setResponse(dio, '{"data":{"code":"MSG-REQ-001"}}');
      final cancelled = await repository.cancelComplaint(report);
      expect(cancelled.code, 'MSG-REQ-001');
    });

    test('updateComplaint uploads fewer than three new photos', () async {
      final adapter = _JsonAdapter();
      dio.httpClientAdapter = adapter;
      final tempDirectory =
          await Directory.systemTemp.createTemp('failure-report-test-');

      try {
        final photo = File(
          '${tempDirectory.path}${Platform.pathSeparator}photo.jpg',
        );
        await photo.writeAsBytes([1, 2, 3]);

        await repository.updateComplaint(
          ComplaintModel(
            id: '20',
            userId: 3,
            complaintType: 'equipment',
            description: 'Updated description',
            contactName: 'Aye Aye',
            contactPhone: '09770000001',
            photos: [
              ComplaintPhotoModel(
                id: '',
                complaintId: '20',
                imageUrl: photo.path,
              ),
            ],
          ),
        );

        final request = adapter.lastRequestOptions!;
        expect(request.method, 'POST');
        expect(request.uri.path, endsWith('/failure-reports/20'));
        final formData = request.data as FormData;
        expect(formData.fields, contains(const MapEntry('_method', 'PUT')));
        expect(formData.files, hasLength(1));
        expect(formData.files.single.key, 'photos[]');
      } finally {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('updateComplaint resends existing photos with newly added photos',
        () async {
      final adapter = _JsonAdapter();
      dio.httpClientAdapter = adapter;
      final tempDirectory =
          await Directory.systemTemp.createTemp('failure-report-test-');

      try {
        final newPhoto = File(
          '${tempDirectory.path}${Platform.pathSeparator}new-photo.jpg',
        );
        await newPhoto.writeAsBytes([4, 5, 6]);

        await repository.updateComplaint(
          ComplaintModel(
            id: '21',
            userId: 3,
            complaintType: 'equipment',
            description: 'Updated description',
            contactName: 'Aye Aye',
            contactPhone: '09770000001',
            photos: [
              const ComplaintPhotoModel(
                id: '61',
                complaintId: '21',
                imageUrl: 'https://example.test/storage/old-photo.jpg',
              ),
              ComplaintPhotoModel(
                id: '',
                complaintId: '21',
                imageUrl: newPhoto.path,
              ),
            ],
          ),
        );

        expect(
          adapter.requests.any(
            (request) =>
                request.method == 'GET' &&
                request.uri.path == '/storage/old-photo.jpg',
          ),
          isTrue,
        );

        final updateRequest =
            adapter.requests.singleWhere((request) => request.method == 'POST');
        final formData = updateRequest.data as FormData;
        expect(formData.files, hasLength(2));
        expect(
          formData.files.map((file) => file.key),
          everyElement('photos[]'),
        );
      } finally {
        await tempDirectory.delete(recursive: true);
      }
    });
  });

  group('ComplaintController', () {
    test('fetchComplaints filters reports by broadband account', () async {
      _setResponse(
        dio,
        '''
        {
          "data": [
            {
              "id": 31,
              "broadband_account_number": "FTTH123456789",
              "failure_type": "no_internet"
            },
            {
              "id": 32,
              "broadband_account_number": "CG987654321",
              "failure_type": "slow"
            }
          ]
        }
        ''',
      );
      final controller = ComplaintController(repository);
      addTearDown(controller.dispose);

      await controller.fetchComplaints(accountNumber: ' ftth123456789 ');

      expect(controller.state.reports, hasLength(1));
      expect(controller.state.reports.single.id, '31');
    });

    test('stores offline submission failures like installation requests',
        () async {
      dio.httpClientAdapter = _JsonAdapter(
        errorType: DioExceptionType.connectionError,
      );
      final controller = ComplaintController(repository);
      addTearDown(controller.dispose);

      await expectLater(
        controller.submitComplaint(
          broadbandAccount: 'CG000001',
          complaintType: 'no_internet',
          description: 'Connection is down',
          contactName: 'Test User',
          contactPhone: '09700000000',
          userId: 1,
        ),
        throwsA(isA<ApiException>()),
      );

      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.errorMessage, 'api.offline');
    });

    test('preserves backend message codes on failed submission', () async {
      _setResponse(
        dio,
        '{"code":"MSG-REQ-003","message":"Request rejected"}',
        statusCode: 422,
      );
      final controller = ComplaintController(repository);
      addTearDown(controller.dispose);

      await expectLater(
        controller.submitComplaint(
          broadbandAccount: 'CG000001',
          complaintType: 'no_internet',
          description: 'Connection is down',
          contactName: 'Test User',
          contactPhone: '09700000000',
          userId: 1,
        ),
        throwsA(isA<ApiException>()),
      );

      expect(controller.state.errorMessage, 'Request rejected');
    });

    test('does not report a failed submission as saved', () async {
      final controller = ComplaintController(_FailingRepository(dio));
      addTearDown(controller.dispose);

      await expectLater(
        controller.submitComplaint(
          broadbandAccount: 'CG000001',
          complaintType: 'no_internet',
          description: 'Connection is down',
          contactName: 'Test User',
          contactPhone: '09700000000',
          userId: 1,
        ),
        throwsA(isA<ApiException>()),
      );

      expect(controller.state.reports, isEmpty);
      expect(controller.state.isSubmitting, isFalse);
      expect(controller.state.errorMessage, 'api.server');
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
    this.body = '{"data":[]}',
    this.statusCode = 200,
    this.errorType,
  });

  final String body;
  final int statusCode;
  final DioExceptionType? errorType;
  final List<RequestOptions> requests = [];
  RequestOptions? lastRequestOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (errorType != null) {
      throw DioException(
        requestOptions: options,
        type: errorType!,
      );
    }
    await requestStream?.drain<void>();
    requests.add(options);
    lastRequestOptions = options;
    if (options.method == 'GET' &&
        options.uri.path.endsWith('/old-photo.jpg')) {
      return ResponseBody.fromBytes(
        [1, 2, 3],
        statusCode,
        headers: {
          Headers.contentTypeHeader: ['image/jpeg'],
        },
      );
    }

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

class _FailingRepository extends ComplaintRepository {
  _FailingRepository(Dio dio) : super(dio);

  @override
  Future<ComplaintSaveResult> submitComplaint(ComplaintModel report) {
    throw const ApiException(ApiFailure.server);
  }
}
