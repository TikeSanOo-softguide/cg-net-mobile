import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/relocation/relocation_request_model.dart';

class RelocationRepository {
  RelocationRepository(this._dio);

  final Dio _dio;

  Future<List<RelocationRequestModel>> fetchRequests() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.relocationRequests,
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
            (item) => RelocationRequestModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<RelocationRequestModel> createRequest(
    RelocationRequestModel request,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.createRelocationRequest,
        data: request.toJson(),
      );
      return _requestFromResponse(response.data, request);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<RelocationRequestModel> updateRequest(
    RelocationRequestModel request,
  ) async {
    if (request.id.trim().isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'relocations.required_id'.tr(),
      );
    }

    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.relocationRequest(request.id),
        data: request.toJson(),
      );
      return _requestFromResponse(response.data, request);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> cancelRequest(String requestId) async {
    if (requestId.isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'relocations.required_id'.tr(),
      );
    }

    try {
      await _dio.patch<dynamic>(
        ApiEndpoints.cancelRelocationRequest(requestId),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> deleteRequest(String requestId) async {
    if (requestId.isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'relocations.required_id'.tr(),
      );
    }

    try {
      await _dio.delete<dynamic>(
        ApiEndpoints.relocationRequest(requestId),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  RelocationRequestModel _requestFromResponse(
    Object? data,
    RelocationRequestModel fallback,
  ) {
    if (data is Map) {
      final responseData = data['data'] is Map ? data['data'] : data;
      if (responseData is Map && responseData['id'] != null) {
        return RelocationRequestModel.fromJson(
          Map<String, dynamic>.from(responseData),
        );
      }
    }
    return fallback;
  }
}

final relocationRepositoryProvider = Provider<RelocationRepository>((ref) {
  return RelocationRepository(ref.watch(dioProvider));
});
