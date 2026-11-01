import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/installation_application/installation_application_model.dart';

typedef InstallationApplicationOptions = List<InstallationApplicationOption>;

class InstallationApplicationRepository {
  InstallationApplicationRepository(this._dio);

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
            value == null || (value is String && value.trim().isEmpty),
      );
    return payload;
  }

  Future<InstallationApplicationSaveResult> createRequest(
    InstallationApplicationModel request,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.createInstallationApplicationRequest,
        data: _payload(request),
      );
      return InstallationApplicationSaveResult(
        request: _requestFromResponse(response.data, request),
        code: _messageCode(response.data),
      );
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

  Future<InstallationApplicationSaveResult> updateRequest(
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
      return InstallationApplicationSaveResult(
        request: _requestFromResponse(response.data, request),
        code: _messageCode(response.data),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String?> cancelRequest(String requestId) async {
    if (requestId.trim().isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'requests.required_id'.tr(),
      );
    }

    try {
      final response = await _dio.patch<dynamic>(
        ApiEndpoints.cancelInstallationRequest(requestId),
      );
      final data = response.data;
      if (data is Map && data['code'] is String) {
        return data['code'] as String;
      }
      return null;
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

  String? _messageCode(Object? data) {
    if (data is Map && data['code'] is String) {
      return data['code'] as String;
    }
    return null;
  }
}

class InstallationApplicationSaveResult {
  const InstallationApplicationSaveResult({
    required this.request,
    this.code,
  });

  final InstallationApplicationModel request;
  final String? code;
}

final installationApplicationRepositoryProvider =
    Provider<InstallationApplicationRepository>((ref) {
  return InstallationApplicationRepository(
    ref.watch(dioProvider),
  );
});
