import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/requests/change_password/change_password_model.dart';

class ChangeWifiPasswordRepository {
  ChangeWifiPasswordRepository(this._dio);

  final Dio _dio;

  Future<List<ChangePasswordRequestModel>> fetchRequests() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.changeWifiPasswordRequests,
      );

      final data = response.data;

      final List list = data is Map && data['data'] is List
          ? data['data'] as List
          : (data is List ? data : []);

      return list
          .whereType<Map>()
          .map(
            (item) => ChangePasswordRequestModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChangeWifiPasswordCancelResult> cancelRequest(
    ChangePasswordRequestModel item,
  ) async {
    final requestId = item.id;

    if (requestId.isEmpty) {
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Request ID is missing',
      );
    }

    try {
      final response = await _dio.patch<dynamic>(
        ApiEndpoints.cancelChangeWifiPasswordRequest(requestId),
      );
      return ChangeWifiPasswordCancelResult(code: _messageCode(response.data));
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChangeWifiPasswordSaveResult> updateRequest(
    ChangePasswordRequestModel request,
  ) async {
    if (request.id.trim().isEmpty) {
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Request ID is missing',
      );
    }

    try {
      final response = await _dio.put<dynamic>(
        ApiEndpoints.changeWifiPasswordRequest(request.id),
        data: {
          ...request.toJson(),
          'new_wifi_name': request.newWifiName,
        },
      );
      final data = response.data;
      return ChangeWifiPasswordSaveResult(
        request: data is Map
            ? ChangePasswordRequestModel.fromJson(
                Map<String, dynamic>.from(data),
              )
            : request,
        code: _messageCode(data),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<ChangeWifiPasswordSaveResult> submitWifiPasswordChange({
    required String broadbandAccountNumber,
    required String contactName,
    required String contactPhone,
    required String newPassword,
    required int userId,
    String? newWifiName,
  }) async {
    final model = ChangePasswordRequestModel(
      id: '',
      userId: userId,
      broadbandAccountNumber: broadbandAccountNumber,
      contactName: contactName,
      contactPhone: contactPhone,
      newWifiName: newWifiName,
      newPassword: newPassword,
      status: 'under_review',
    );

    return await submitRequest(model);
  }

  Future<ChangeWifiPasswordSaveResult> submitRequest(
      ChangePasswordRequestModel request) async {
    final payload = request.toJson();

    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.changeWifiPassword,
        data: payload,
      );

      final data = response.data;
      return ChangeWifiPasswordSaveResult(
        request: data is Map
            ? ChangePasswordRequestModel.fromJson(
                Map<String, dynamic>.from(data),
              )
            : request,
        code: _messageCode(data),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  String? _messageCode(Object? data) {
    if (data is! Map) return null;

    final code = data['code']?.toString().trim();
    if (code != null && code.isNotEmpty) return code;

    return _messageCode(data['data']);
  }
}

class ChangeWifiPasswordSaveResult {
  const ChangeWifiPasswordSaveResult({
    required this.request,
    this.code,
  });

  final ChangePasswordRequestModel request;
  final String? code;
}

class ChangeWifiPasswordCancelResult {
  const ChangeWifiPasswordCancelResult({this.code});

  final String? code;
}

final changeWifiPasswordRepositoryProvider =
    Provider<ChangeWifiPasswordRepository>((ref) {
  return ChangeWifiPasswordRepository(ref.watch(dioProvider));
});
