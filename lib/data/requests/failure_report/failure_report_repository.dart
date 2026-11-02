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

  String? _messageCode(Object? data) {
    if (data is Map && data['code'] is String) {
      return data['code'] as String;
    }
    return null;
  }

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

  Future<FailureReportCancelResult> cancelReport(
    FailureReportModel item,
  ) async {
    final reportId = item.id;
    if (reportId.isEmpty) {
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Failure report ID is missing',
      );
    }

    try {
      final response = await _dio.patch<dynamic>(
        '${ApiEndpoints.failureReports}/$reportId/cancel',
      );
      return FailureReportCancelResult(code: _messageCode(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<FailureReportSaveResult> submitReport(
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

      return FailureReportSaveResult(
        report: data is Map
            ? FailureReportModel.fromJson(Map<String, dynamic>.from(data))
            : report,
        code: _messageCode(data),
      );
    } on DioException catch (error) {
      debugPrint(
        'FAILURE REPORT ERROR: '
        '${error.response?.statusCode} - '
        '${error.response?.data}',
      );

      throw ApiException.fromDio(error);
    }
  }

  Future<FailureReportSaveResult> updateReport(
    FailureReportModel report,
  ) async {
    try {
      final payload = report.toJson()
        ..remove('photos')
        ..remove('user_id')
        ..remove('status');
      final photos = report.photos
          .where((photo) => photo.imageUrl.trim().isNotEmpty)
          .toList();

      final Response<dynamic> response;
      if (photos.isEmpty) {
        response = await _dio.put<dynamic>(
          ApiEndpoints.failureReportDetail(report.id),
          data: payload,
        );
      } else {
        final formData = FormData();
        formData.fields.add(const MapEntry('_method', 'PUT'));
        payload.forEach((key, value) {
          if (value != null) {
            formData.fields.add(MapEntry(key, value.toString()));
          }
        });
        for (var i = 0; i < photos.length; i++) {
          final path = photos[i].imageUrl.trim();
          final uri = Uri.tryParse(path);
          final isRemote =
              uri?.scheme == 'http' || uri?.scheme == 'https';
          final rawFilename = (uri?.path ?? path)
              .split('/')
              .last
              .toLowerCase();
          final ext = rawFilename.endsWith('.png')
              ? 'png'
              : (rawFilename.endsWith('.webp') ? 'webp' : 'jpeg');
          final filename = 'photo_${i + 1}.$ext';
          final multipartFile = isRemote
              ? await _downloadPhoto(path, filename, ext)
              : await MultipartFile.fromFile(
                  path,
                  filename: filename,
                  contentType: DioMediaType('image', ext),
                );
          formData.files.add(
            MapEntry(
              'photos[]',
              multipartFile,
            ),
          );
        }
        response = await _dio.post<dynamic>(
          ApiEndpoints.failureReportDetail(report.id),
          data: formData,
        );
      }

      final data = response.data;
      return FailureReportSaveResult(
        report: data is Map
            ? FailureReportModel.fromJson(Map<String, dynamic>.from(data))
            : report,
        code: _messageCode(data),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<MultipartFile> _downloadPhoto(
    String url,
    String filename,
    String extension,
  ) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Existing failure report photo returned no image data',
      );
    }

    return MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: DioMediaType('image', extension),
    );
  }
}

class FailureReportSaveResult {
  const FailureReportSaveResult({
    required this.report,
    this.code,
  });

  final FailureReportModel report;
  final String? code;
}

class FailureReportCancelResult {
  const FailureReportCancelResult({this.code});

  final String? code;
}

final failureReportRepositoryProvider =
    Provider<FailureReportRepository>((ref) {
  return FailureReportRepository(ref.watch(dioProvider));
});
