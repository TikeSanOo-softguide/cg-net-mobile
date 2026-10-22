import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';

typedef InstallationApplicationOptions = ({
  List<InstallationApplicationOption> packages,
  List<InstallationApplicationOption> areas,
});

class InstallationApplicationRepository {
  InstallationApplicationRepository(this._dio);

  static const _maxPhotoBytes = 2 * 1024 * 1024;

  final Dio _dio;

  Future<InstallationApplicationOptions> fetchRequestOptions() async {
    try {
      final responses = await Future.wait([
        _dio.get<dynamic>(ApiEndpoints.availablePlans),
        _dio.get<dynamic>(ApiEndpoints.availableAreas),
      ]);
      return (
        packages: _optionsFromResponse(responses[0].data, activeOnly: true),
        areas: _optionsFromResponse(responses[1].data),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<InstallationApplicationModel>> fetchRequests() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.installationApplicationRequests,
      );
      final data = response.data;
      final List items = data is Map && data['data'] is List
          ? data['data'] as List
          : data is List
              ? data
              : const [];

      return items
          .whereType<Map>()
          .map(
            (item) => InstallationApplicationModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<InstallationApplicationModel> createRequest(
    InstallationApplicationModel request, {
    required List<XFile> photos,
  }) async {
    if (photos.length != 2) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'installationApplication.photos_required'.tr(),
      );
    }
    for (final photo in photos) {
      final extension = photo.name.split('.').last.toLowerCase();
      if (!{'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
        throw ApiException(
          ApiFailure.unknown,
          detail: 'installationApplication.photo_type_error'.tr(),
        );
      }
      if (await photo.length() > _maxPhotoBytes) {
        throw ApiException(
          ApiFailure.unknown,
          detail: 'installationApplication.photo_size_error'.tr(),
        );
      }
    }

    try {
      final payload = request.toJson()
        ..remove('user_id')
        ..remove('status')
        ..remove('photos');
      if (request.note == null) payload.remove('note');
      final formData = FormData.fromMap(payload);
      for (var index = 0; index < photos.length; index++) {
        final photo = photos[index];
        formData.files.add(
          MapEntry(
            'photos[$index]',
            MultipartFile.fromBytes(
              await photo.readAsBytes(),
              filename: photo.name,
            ),
          ),
        );
      }
      final response = await _dio.post<dynamic>(
        ApiEndpoints.createInstallationApplicationRequest,
        data: formData,
      );
      return _requestFromResponse(response.data, request);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<InstallationApplicationOption> _optionsFromResponse(
    Object? response, {
    bool activeOnly = false,
  }) {
    final items = response is Map && response['data'] is List
        ? response['data'] as List
        : response is List
            ? response
            : null;
    if (items == null) {
      throw const FormatException(
        'Unexpected installation application options response',
      );
    }
    return items.whereType<Map>().where((item) {
      if (!activeOnly || item['is_active'] == null) return true;
      final active = item['is_active'];
      return active == true || active == 1 || active == '1';
    }).map((item) {
      return InstallationApplicationOption.fromJson(
        Map<String, dynamic>.from(item),
      );
    }).toList();
  }

  Future<InstallationApplicationModel> updateRequest(
    InstallationApplicationModel request,
  ) async {
    if (request.id.trim().isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'requests.required_id'.tr(),
      );
    }

    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.installationApplicationRequest(request.id),
        data: request.toJson(),
      );
      return _requestFromResponse(response.data, request);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> cancelRequest(String requestId) async {
    if (requestId.trim().isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'requests.required_id'.tr(),
      );
    }

    try {
      await _dio.patch<dynamic>(
        ApiEndpoints.cancelInstallationRequest(requestId),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteRequest(String requestId) async {
    if (requestId.trim().isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'requests.required_id'.tr(),
      );
    }

    try {
      await _dio.delete<dynamic>(
        ApiEndpoints.installationApplicationRequest(requestId),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  InstallationApplicationModel _requestFromResponse(
    Object? data,
    InstallationApplicationModel fallback,
  ) {
    if (data is Map) {
      final responseData = data['data'] is Map ? data['data'] : data;
      if (responseData is Map && responseData['id'] != null) {
        return InstallationApplicationModel.fromJson(
          Map<String, dynamic>.from(responseData),
        );
      }
    }
    return fallback;
  }
}

final installationApplicationRepositoryProvider =
    Provider<InstallationApplicationRepository>((ref) {
  return InstallationApplicationRepository(ref.watch(dioProvider));
});
