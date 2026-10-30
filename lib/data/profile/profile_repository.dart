import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/network/get_retry_interceptor.dart';
import '../../core/storage/secure_storage/secure_storage.dart';
import '../../models/user_model/user_model.dart';

class ProfileRepository {
  ProfileRepository(this._dio, this._secureStorage);

  final Dio _dio;
  final SecureStorage _secureStorage;

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
        final profile =
            UserProfileModel.fromJson(Map<String, dynamic>.from(data));
        await _cacheProfile(profile);
        return profile;
      }
      throw const ApiException(
        ApiFailure.unknown,
        detail: 'Invalid profile response',
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<UserProfileModel?> readCachedProfile() async {
    final cached = await _secureStorage.readCachedProfile();
    if (cached == null || cached.isEmpty) return null;

    try {
      final decoded = jsonDecode(cached);
      if (decoded is! Map) {
        throw const FormatException('Cached profile is not a JSON object.');
      }
      return UserProfileModel.fromJson(Map<String, dynamic>.from(decoded));
    } on FormatException {
      await _secureStorage.clearCachedProfile();
      return null;
    } on TypeError {
      await _secureStorage.clearCachedProfile();
      return null;
    }
  }

  Future<void> _cacheProfile(UserProfileModel profile) {
    final hasBroadbandAccount = profile.accountNumber.trim().isNotEmpty;

    return _secureStorage.writeCachedProfile(
      jsonEncode(
        {
          'data': {
            'user': {
              'id': profile.id,
              'phone': profile.phone,
              'name': profile.fullName,
              'status': profile.status,
              if (profile.username != null) 'username': profile.username,
            },
            'account': hasBroadbandAccount
                ? {
                    'id': profile.id,
                    'account': profile.accountNumber,
                    'name': profile.accountName,
                    'mobile': profile.accountPhone,
                    'account_status': profile.accountStatus,
                    'status': profile.accountStatus,
                    'productName': profile.productName,
                    'productPrice': profile.productPrice,
                    'starttime': profile.startTime,
                    'endtime': profile.endTime,
                    'productLine': profile.productLine,
                    'productSpeed': profile.productSpeed,
                    'address': profile.address,
                    'area': profile.area,
                    'onlineStatus': profile.onlineStatus,
                  }
                : {},
            'broadbandAccount': hasBroadbandAccount
                ? {
                    'account_number': profile.accountNumber,
                    if (profile.serviceType != null)
                      'service_type': profile.serviceType,
                  }
                : null,
            'wallet': {'balance': profile.walletBalance},
          },
        },
      ),
    );
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
        final profile =
            UserProfileModel.fromJson(Map<String, dynamic>.from(data));
        await _cacheProfile(profile);
        return profile;
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
  return ProfileRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

final userProfileProvider = FutureProvider.autoDispose<UserProfileModel>((ref) {
  return ref.watch(profileRepositoryProvider).fetchProfile();
});

final cachedUserProfileProvider =
    FutureProvider.autoDispose<UserProfileModel?>((ref) {
  return ref.watch(profileRepositoryProvider).readCachedProfile();
});
