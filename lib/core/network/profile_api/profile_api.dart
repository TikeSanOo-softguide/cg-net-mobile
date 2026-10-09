import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/user_model/user_model.dart';
import '../api_endpoints/api_endpoints.dart';
import '../api_exception.dart';
import '../dio_client/dio_client.dart';
import '../get_retry_interceptor.dart';

class ProfileApi {
  ProfileApi(this._dio);

  final Dio _dio;

  /// Throws [ApiException]; `unauthorized` means the stored token is no
  /// longer valid (the interceptor has already cleared it).
  Future<void> checkSession() async {
    await _send(
      () => _dio.get(
        ApiEndpoints.profile,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          extra: {GetRetryInterceptor.skipKey: true},
        ),
      ),
    );
  }

  Future<UserProfileModel> fetchProfile() async {
    final response = await _send(
      () => _dio.get(
        ApiEndpoints.profile,
      ),
    );
    final data = response.data;
    if (data is Map) {
      return UserProfileModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ApiException(
      ApiFailure.unknown,
      detail: 'Invalid profile response',
    );
  }

  Future<UserProfileModel> updateProfile({
    required String fullName,
  }) async {
    final payload = {
      'name': fullName,
      'full_name': fullName,
    };

    final response = await _send(
      () => _dio.patch(
        ApiEndpoints.updateProfile,
        data: payload,
      ),
    );

    final data = response.data;
    if (data is Map) {
      return UserProfileModel.fromJson(Map<String, dynamic>.from(data));
    }

    throw const ApiException(
      ApiFailure.unknown,
      detail: 'Invalid update profile response',
    );
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

final profileApiProvider = Provider<ProfileApi>((ref) {
  return ProfileApi(ref.watch(dioProvider));
});
