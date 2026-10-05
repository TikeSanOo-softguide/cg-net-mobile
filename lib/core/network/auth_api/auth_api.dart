import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_endpoints/api_endpoints.dart';
import '../api_exception.dart';
import '../dio_client/dio_client.dart';
import '../get_retry_interceptor.dart';

class OtpChallengeResult {
  const OtpChallengeResult({required this.challengeId, this.debugOtp});

  final String challengeId;
  final String? debugOtp;
}

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<OtpChallengeResult> requestOtp(String phone) async {
    final response = await _send(
      () => _dio.post(
        ApiEndpoints.requestOtp,
        data: {'phone': phone},
      ),
    );
    final data = response.data;
    final debugOtp = data is Map ? data['debug_otp']?.toString() : null;

    return OtpChallengeResult(
      challengeId: data['challenge_id'] as String,
      debugOtp: debugOtp == null || debugOtp.isEmpty ? null : debugOtp,
    );
  }

  Future<String> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    final response = await _send(
      () => _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'challenge_id': challengeId, 'code': code},
      ),
    );
    return response.data['verification_token'] as String;
  }

  Future<String> completeRegistration({
    required String verificationToken,
    required String name,
    required String password,
  }) async {
    final response = await _send(
      () => _dio.post(
        ApiEndpoints.completeRegistration,
        data: {
          'verification_token': verificationToken,
          'name': name,
          'password': password,
          'password_confirmation': password,
          'platform':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      ),
    );
    return response.data['token'] as String;
  }

  Future<void> logout() async {
    await _send(
      () => _dio.post(
        ApiEndpoints.logout,
      ),
    );
  }

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

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});
