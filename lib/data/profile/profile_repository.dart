import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/network/get_retry_interceptor.dart';
import '../../models/user_model/user_model.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<void> checkSession() async {
    try {
      await _dio.get<dynamic>(
        ApiEndpoints.profile,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          extra: {GetRetryInterceptor.skipKey: true},
        ),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserProfileModel> fetchProfile() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.profile,
      );
      final data = response.data;
      if (data is Map) {
        return UserProfileModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Invalid profile response',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserProfileModel> updateProfile({
    required String fullName,
  }) async {
    final payload = {
      'name': fullName,
      'full_name': fullName,
    };

    try {
      final response = await _dio.patch<dynamic>(
        ApiEndpoints.updateProfile,
        data: payload,
      );
      final data = response.data;
      if (data is Map) {
        return UserProfileModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Invalid update profile response',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

final userProfileProvider =
    FutureProvider.autoDispose<UserProfileModel>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});
