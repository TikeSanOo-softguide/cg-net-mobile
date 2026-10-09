import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/requests/change_password/change_password_model.dart';
import '../../api_endpoints/api_endpoints.dart';
import '../../api_exception.dart';
import '../../dio_client/dio_client.dart';

class ChangeWifiPasswordApi {
  ChangeWifiPasswordApi(this._dio);

  final Dio _dio;

  Future<List<ChangePasswordRequestModel>> fetchRequests() async {
    final endpoints = [
      '/change-password-requests',
      '/customer/change-password-requests',
    ];

    for (final ep in endpoints) {
      try {
        final response = await _send(() => _dio.get(ep));
        final data = response.data;
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : (data is List ? data : []);
        return list
            .map((item) => ChangePasswordRequestModel.fromJson(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList();
      } on ApiException catch (e) {
        if (e.failure == ApiFailure.server || e.failure == ApiFailure.unknown) {
          continue;
        }
        rethrow;
      }
    }
    return [];
  }

  Future<void> cancelRequest(ChangePasswordRequestModel item) async {
    final payload = {
      ...item.toJson(),
      'status': 'cancelled',
    };

    final requestId = item.id;

    final endpoints = [
      if (requestId.isNotEmpty) '/change-password-requests/$requestId/cancel',
      if (requestId.isNotEmpty) '/customer/change-password-requests/$requestId/cancel',
      if (requestId.isNotEmpty) '/change-password-requests/$requestId',
      if (requestId.isNotEmpty) '/customer/change-password-requests/$requestId',
      '/change-password-requests/cancel',
    ];

    ApiException? lastError;

    for (final ep in endpoints) {
      try {
        await _send(() => _dio.post(ep, data: payload));
        return;
      } on ApiException catch (e) {
        lastError = e;
        try {
          await _send(() => _dio.put(ep, data: payload));
          return;
        } on ApiException catch (e2) {
          lastError = e2;
          try {
            await _send(() => _dio.patch(ep, data: payload));
            return;
          } on ApiException catch (e3) {
            lastError = e3;
            try {
              await _send(
                () => _dio.post(
                  ep,
                  data: {
                    '_method': 'PUT',
                    ...payload,
                  },
                ),
              );
              return;
            } on ApiException catch (e4) {
              lastError = e4;
              continue;
            }
          }
        }
      }
    }

    throw lastError ??
        const ApiException(
          ApiFailure.unknown,
          detail: 'Failed to cancel request on server',
        );
  }

  Future<ChangePasswordRequestModel> submitWifiPasswordChange({
    required String broadbandAccountNumber,
    required String contactName,
    required String contactPhone,
    required String newPassword,
    String? newWifiName,
    int? userId,
  }) async {
    final model = ChangePasswordRequestModel(
      id: '',
      userId: userId ?? 1,
      broadbandAccountNumber: broadbandAccountNumber,
      contactName: contactName,
      contactPhone: contactPhone,
      newWifiName: newWifiName,
      newPassword: newPassword,
      status: 'under_review',
    );

    return await submitRequest(model);
  }

  Future<ChangePasswordRequestModel> submitRequest(
      ChangePasswordRequestModel request) async {
    final payload = request.toJson();

    final response = await _send(
      () => _dio.post(
        ApiEndpoints.changeWifiPassword,
        data: payload,
      ),
    );

    final data = response.data;
    if (data is Map) {
      return ChangePasswordRequestModel.fromJson(
        Map<String, dynamic>.from(data),
      );
    }

    return request;
  }

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final changeWifiPasswordApiProvider = Provider<ChangeWifiPasswordApi>((ref) {
  return ChangeWifiPasswordApi(ref.watch(dioProvider));
});
