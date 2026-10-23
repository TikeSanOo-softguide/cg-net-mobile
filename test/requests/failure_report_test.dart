import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/requests/failure_report/failure_report_repository.dart';
import 'package:cg_net_mobile/models/requests/failure_report/failure_report_model.dart';
import 'package:cg_net_mobile/pages/requests/failure_report/failure_report_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late FailureReportRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = _JsonAdapter();
    repository = FailureReportRepository(dio);
  });

  tearDown(() => dio.close());

  group('FailureReportRepository', () {
    test('fetchReports reads records from a paginated data envelope', () async {
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

      final reports = await repository.fetchReports();

      expect(reports, hasLength(1));
      expect(reports.single.id, '15');
      expect(reports.single.status, 'under_review');
      expect(reports.single.contactName, 'Sophia');
      expect(reports.single.photos, isEmpty);
    });

    test('fetchReports returns approved reports for history', () async {
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

      final reports = await repository.fetchReports();

      expect(reports, hasLength(1));
      expect(reports.single.id, '16');
      expect(reports.single.status, 'approved');
    });

    test('fetchReport loads photo URLs from the detail endpoint', () async {
      _setResponse(dio, '''
        {
          "data": {
            "id": 17,
            "user_id": 3,
            "failure_type": "equipment",
            "description": "Router is damaged",
            "contact_name": "Aye Aye",
            "contact_phone": "09770000001",
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

      final report = await repository.fetchReport('17');

      expect(report.id, '17');
      expect(report.photos, hasLength(1));
      expect(
        report.photos.single.imageUrl,
        'https://example.test/storage/report.jpg',
      );
    });
  });

  group('FailureReportController', () {
    test('does not report a failed submission as saved', () async {
      final controller = FailureReportController(_FailingRepository(dio));
      addTearDown(controller.dispose);

      final result = await controller.submitReport(
        broadbandAccount: 'CG000001',
        failureType: 'no_internet',
        description: 'Connection is down',
        contactName: 'Test User',
        contactPhone: '09700000000',
        userId: 1,
      );

      expect(result, isNull);
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
  });

  final String body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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

class _FailingRepository extends FailureReportRepository {
  _FailingRepository(Dio dio) : super(dio);

  @override
  Future<FailureReportModel> submitReport(FailureReportModel report) {
    throw const ApiException(ApiFailure.server);
  }
}
