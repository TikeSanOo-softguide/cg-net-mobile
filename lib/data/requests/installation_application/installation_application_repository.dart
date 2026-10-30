import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';

typedef InstallationApplicationOptions = List<InstallationApplicationOption>;

class InstallationApplicationRepository {
  InstallationApplicationRepository(this._dio);

  static const _maxPhotoBytes = 2 * 1024 * 1024;

  final Dio _dio;

  Future<InstallationApplicationOptions> fetchProducts(
    String serviceType,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.installationProducts,
        queryParameters: {'service_type': serviceType},
      );
      return _optionsFromResponse(response.data);
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

  Map<String, dynamic> _payload(InstallationApplicationModel request) {
    final payload = request.toJson()
      ..remove('user_id')
      ..remove('status')
      ..remove('photos');
      payload.removeWhere(
        (key, value) =>
            value == null ||
            (value is String && value.trim().isEmpty) ||
            key == 'id_type' ||
            key == 'id_number' ||
            key == 'package_id',
      );
    return payload;
  }

  Future<InstallationApplicationModel> createRequest(
    InstallationApplicationModel request, {
    List<XFile> photos = const [],
  }) async {
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
      final formData = FormData.fromMap(_payload(request));
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

  List<InstallationApplicationOption> _optionsFromResponse(Object? response) {
    Object? raw = response;
    if (response is Map && response['data'] is List) {
      raw = response['data'];
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) {
          try {
            return InstallationApplicationOption.fromJson(
              Map<String, dynamic>.from(item),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<InstallationApplicationOption>()
        .toList();
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
        data: _payload(request),
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
  return InstallationApplicationRepository(
    ref.watch(dioProvider),
  );
});
