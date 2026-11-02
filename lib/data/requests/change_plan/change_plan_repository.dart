import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/change_plan/change_plan_request_model.dart';

class ChangePlanRepository {
  ChangePlanRepository(this._dio);

  final Dio _dio;

  Future<List<ChangePlanRequestModel>> fetchRequests() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.changePlanRequests);
      final data = response.data;
      final List items = data is Map && data['data'] is List
          ? data['data'] as List
          : data is List
              ? data
              : const [];

      return items
          .whereType<Map>()
          .map(
            (item) => ChangePlanRequestModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChangePlanSaveResult> createRequest(
    ChangePlanRequestModel request,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.createChangePlanRequest,
        data: request.toJson(),
      );
      return ChangePlanSaveResult(
        request: _requestFromResponse(response.data, request),
        code: _messageCode(response.data),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<String?> deleteRequest(String requestId) async {
    if (requestId.isEmpty) {
      throw ApiException(
        ApiFailure.unknown,
        detail: 'requests.required_id'.tr(),
      );
    }

    try {
      final response = await _dio.delete<dynamic>(
        ApiEndpoints.changePlanRequest(requestId),
      );
      return _messageCode(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  ChangePlanRequestModel _requestFromResponse(
    Object? data,
    ChangePlanRequestModel fallback,
  ) {
    if (data is Map) {
      final responseData = data['data'] is Map ? data['data'] : data;
      if (responseData is Map && responseData['id'] != null) {
        return ChangePlanRequestModel.fromJson(
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

class ChangePlanSaveResult {
  const ChangePlanSaveResult({
    required this.request,
    this.code,
  });

  final ChangePlanRequestModel request;
  final String? code;
}

final changePlanRepositoryProvider = Provider<ChangePlanRepository>((ref) {
  return ChangePlanRepository(ref.watch(dioProvider));
});
