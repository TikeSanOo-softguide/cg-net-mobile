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

  Future<void> cancelRequest(
      ChangePasswordRequestModel item,
      ) async {
    final requestId = item.id;

    if (requestId.isEmpty) {
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Request ID is missing',
      );
    }

    final payload = {
      ...item.toJson(),
      'status': 'cancelled',
    };

    try {
      await _dio.put<dynamic>(
        ApiEndpoints.cancelChangeWifiPasswordRequest(requestId),
        data: payload,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }



  Future<ChangePasswordRequestModel> submitWifiPasswordChange({
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

  Future<ChangePasswordRequestModel> submitRequest(
      ChangePasswordRequestModel request) async {
    final payload = request.toJson();

    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.changeWifiPassword,
        data: payload,
      );

      final data = response.data;
      if (data is Map) {
        return ChangePasswordRequestModel.fromJson(
          Map<String, dynamic>.from(data),
        );
      }

      return request;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final changeWifiPasswordRepositoryProvider =
    Provider<ChangeWifiPasswordRepository>((ref) {
  return ChangeWifiPasswordRepository(ref.watch(dioProvider));
});
