import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/complaint/complaint_model.dart';

List<dynamic> _complaintItemsFromResponse(Object? payload) {
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
        return _complaintItemsFromResponse(value);
      }
    }

    if (payload.containsKey('id')) return [payload];
  }

  return const [];
}

class ComplaintRepository {
  ComplaintRepository(this._dio);

  final Dio _dio;

  String? _messageCode(Object? data) {
    if (data is! Map) return null;

    final code = data['code']?.toString().trim();
    if (code != null && code.isNotEmpty) {
      return code;
    }

    return data['data'] is Map ? _messageCode(data['data']) : null;
  }

  Future<List<ComplaintModel>> fetchComplaints() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.complaints,
      );
      final list = _complaintItemsFromResponse(response.data);

      return list
          .whereType<Map>()
          .map(
            (item) => ComplaintModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ComplaintModel> fetchComplaint(String complaintId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.complaintDetail(complaintId),
      );
      final payload = response.data;
      if (payload is! Map) {
        throw const ApiException(
          ApiFailure.unknown,
          detail: 'Invalid complaint detail response',
        );
      }

      return ComplaintModel.fromJson(
        Map<String, dynamic>.from(payload),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ComplaintCancelResult> cancelComplaint(
    ComplaintModel item,
  ) async {
    final complaintId = item.id;
    if (complaintId.isEmpty) {
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Complaint ID is missing',
      );
    }

    try {
      final response = await _dio.patch<dynamic>(
        '${ApiEndpoints.complaints}/$complaintId/cancel',
      );
      final code = _messageCode(response.data);
      return ComplaintCancelResult(code: code);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ComplaintSaveResult> submitComplaint(
    ComplaintModel report,
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
        ApiEndpoints.complaintCreate,
        data: formData,
      );
      final data = response.data;
      final code = _messageCode(data);

      return ComplaintSaveResult(
        report: data is Map
            ? ComplaintModel.fromJson(Map<String, dynamic>.from(data))
            : report,
        code: code,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ComplaintSaveResult> updateComplaint(
    ComplaintModel report,
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
          ApiEndpoints.complaintDetail(report.id),
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
          final isRemote = uri?.scheme == 'http' || uri?.scheme == 'https';
          final rawFilename = (uri?.path ?? path).split('/').last.toLowerCase();
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
          ApiEndpoints.complaintDetail(report.id),
          data: formData,
        );
      }

      final data = response.data;
      final code = _messageCode(data);
      return ComplaintSaveResult(
        report: data is Map
            ? ComplaintModel.fromJson(Map<String, dynamic>.from(data))
            : report,
        code: code,
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
        detail: 'Existing complaint photo returned no image data',
      );
    }

    return MultipartFile.fromBytes(
      bytes,
      filename: filename,
      contentType: DioMediaType('image', extension),
    );
  }
}

class ComplaintSaveResult {
  const ComplaintSaveResult({
    required this.report,
    this.code,
  });

  final ComplaintModel report;
  final String? code;
}

class ComplaintCancelResult {
  const ComplaintCancelResult({this.code});

  final String? code;
}

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  return ComplaintRepository(ref.watch(dioProvider));
});
