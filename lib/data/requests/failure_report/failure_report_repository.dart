import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/failure_report/failure_report_model.dart';

List<dynamic> _reportItemsFromResponse(Object? payload) {
  if (payload is List) return payload;

  if (payload is Map) {
    for (final key in [
      'data',
      'reports',
      'failure_reports',
      'items',
      'results'
    ]) {
      final value = payload[key];
      if (value is List || value is Map) {
        return _reportItemsFromResponse(value);
      }
    }

    if (payload.containsKey('id')) return [payload];
  }

  return const [];
}

void _debugPrintReportPhotos(List<dynamic> reports) {
  if (!kDebugMode) return;

  for (var index = 0; index < reports.length; index++) {
    final report = reports[index];
    if (report is! Map) continue;

    final rawPhotos = report['photos'] ?? report['failure_photos'];
    if (rawPhotos is! List) {
      debugPrint('[failure-reports] report[$index]: photos field missing');
      continue;
    }
  }
}

class FailureReportRepository {
  FailureReportRepository(this._dio);

  final Dio _dio;

  Future<List<FailureReportModel>> fetchReports() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.failureReports,
      );
      final list = _reportItemsFromResponse(response.data);
      _debugPrintReportPhotos(list);

      return list
          .whereType<Map>()
          .map(
            (item) =>
                FailureReportModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FailureReportModel> fetchReport(String reportId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.failureReportDetail(reportId),
      );
      final payload = response.data;
      if (payload is! Map) {
        throw const ApiException(
          ApiFailure.unknown,
          detail: 'Invalid failure report detail response',
        );
      }

      return FailureReportModel.fromJson(
        Map<String, dynamic>.from(payload),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> cancelReport(FailureReportModel item) async {
    final reportId = item.id;
    if (reportId.isEmpty) {
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Failure report ID is missing',
      );
    }

    try {
      await _dio.patch<dynamic>(
        '${ApiEndpoints.failureReports}/$reportId/cancel',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FailureReportModel> submitReport(
    FailureReportModel report,
  ) async {
    try {
      final payload = report.toJson();

      // Remove photos from the normal JSON fields.
      payload.remove('photos');

      final formData = FormData();

      // Add normal text fields.
      payload.forEach((key, value) {
        if (value != null) {
          formData.fields.add(
            MapEntry(key, value.toString()),
          );
        }
      });

      // Add each image file with explicit image MIME type and extension for Laravel validation.
      for (int i = 0; i < report.photos.length; i++) {
        final photo = report.photos[i];
        final path = photo.imageUrl.trim();

        if (path.isEmpty || path.startsWith('http')) {
          continue;
        }

        final rawFilename = path.split('/').last.toLowerCase();
        final ext = rawFilename.endsWith('.png')
            ? 'png'
            : (rawFilename.endsWith('.webp') ? 'webp' : 'jpeg');
        final uploadFilename = 'photo_${i + 1}.$ext';

        formData.files.add(
          MapEntry(
            'photos[]',
            await MultipartFile.fromFile(
              path,
              filename: uploadFilename,
              contentType: DioMediaType('image', ext),
            ),
          ),
        );
      }

      final response = await _dio.post<dynamic>(
        ApiEndpoints.failureReport,
        data: formData,
      );

      final data = response.data;

      if (data is Map) {
        return FailureReportModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      return report;
    } on DioException catch (error) {
      debugPrint(
        'FAILURE REPORT ERROR: '
        '${error.response?.statusCode} - '
        '${error.response?.data}',
      );

      throw ApiException.fromDio(error);
    }
  }
}

final failureReportRepositoryProvider =
    Provider<FailureReportRepository>((ref) {
  return FailureReportRepository(ref.watch(dioProvider));
});

final failureReportDetailProvider =
    FutureProvider.autoDispose.family<FailureReportModel, String>(
  (ref, reportId) =>
      ref.watch(failureReportRepositoryProvider).fetchReport(reportId),
);
