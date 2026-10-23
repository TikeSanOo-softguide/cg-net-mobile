import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_endpoints/api_endpoints.dart';
import '../api_exception.dart';
import '../auth_interceptor/auth_interceptor.dart';
import '../dio_client/dio_client.dart';
import '../get_retry_interceptor.dart';

class OtpChallengeResult {
  const OtpChallengeResult({
    required this.challengeId,
    this.debugOtp,
    this.resendAfter = 60,
  });

  final String challengeId;
  final String? debugOtp;

  /// Seconds until the next OTP request is allowed.
  final int resendAfter;
}

class AccountSessionCheckResult {
  const AccountSessionCheckResult({
    required this.showAlert,
  });

  final bool showAlert;

  factory AccountSessionCheckResult.fromJson(Map<String, dynamic> data) {
    final showAlert = data['show_alert'];
    if (showAlert is! bool) {
      throw const ApiException(ApiFailure.unknown);
    }
    return AccountSessionCheckResult(showAlert: showAlert);
  }
}

/// POST /auth/otp/verify — `next_step` drives the post-OTP flow.
class OtpVerifyResult {
  const OtpVerifyResult({
    required this.nextStep,
    this.verificationToken,
    this.accessToken,
  });

  final String nextStep;
  final String? verificationToken;
  final String? accessToken;

  bool get isRegister => nextStep == 'register';
  bool get isPassword => nextStep == 'password';
  bool get isAuthenticated => nextStep == 'authenticated';

  factory OtpVerifyResult.fromJson(Map<String, dynamic> data) {
    final nextStep = data['next_step']?.toString().trim().toLowerCase() ?? '';
    if (nextStep.isEmpty) {
      throw const ApiException(ApiFailure.unknown);
    }
    final verificationToken = data['verification_token']?.toString();
    final accessToken = data['token']?.toString();
    return OtpVerifyResult(
      nextStep: nextStep,
      verificationToken: verificationToken == null || verificationToken.isEmpty
          ? null
          : verificationToken,
      accessToken:
          accessToken == null || accessToken.isEmpty ? null : accessToken,
    );
  }
}

class AuthApi {
  AuthApi(this._dio, this._languageCode);

  final Dio _dio;
  final String Function() _languageCode;

  Future<AccountSessionCheckResult> checkPhoneSession(String phone) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.checkSession,
        data: {'phone': phone},
      );
      final raw = response.data;
      if (raw is! Map) {
        throw const ApiException(ApiFailure.unknown);
      }
      final data =
          raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
      return AccountSessionCheckResult.fromJson(data);
    } on DioException catch (error) {
      throw _otpRequestException(error);
    }
  }

  Future<OtpChallengeResult> requestOtp(String phone) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.requestOtp,
        data: {'phone': phone},
      );
      final data = response.data;
      final debugOtp = data is Map ? data['debug_otp']?.toString() : null;
      final resendAfter = _readPositiveInt(
            data is Map ? data['resend_after'] : null,
          ) ??
          60;

      return OtpChallengeResult(
        challengeId: data['challenge_id'] as String,
        debugOtp: debugOtp == null || debugOtp.isEmpty ? null : debugOtp,
        resendAfter: resendAfter,
      );
    } on DioException catch (error) {
      throw _otpRequestException(error);
    }
  }

  static int? _readPositiveInt(Object? value) {
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  static ApiException _otpRequestException(DioException error) {
    final mapped = ApiException.fromDio(error);
    if (mapped.failure != ApiFailure.tooManyRequests) {
      return mapped;
    }
    final data = error.response?.data;
    final retryAfter = _readPositiveInt(
          data is Map ? data['retry_after'] : null,
        ) ??
        _readPositiveInt(error.response?.headers.value('retry-after'));
    return ApiException(
      ApiFailure.tooManyRequests,
      detail: retryAfter?.toString() ?? mapped.detail,
      statusCode: mapped.statusCode,
      responseData: mapped.responseData,
      code: mapped.code,
      level: mapped.level,
    );
  }

  Future<OtpVerifyResult> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    final response = await _send(
      () => _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'challenge_id': challengeId, 'code': code},
      ),
    );
    final raw = response.data;
    if (raw is! Map) {
      throw const ApiException(ApiFailure.unknown);
    }
    final data =
        raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw);
    return OtpVerifyResult.fromJson(data);
  }

  Future<String> loginWithPassword({
    required String verificationToken,
    required String password,
  }) async {
    final response = await _send(
      () => _dio.post(
        ApiEndpoints.login,
        data: {
          'verification_token': verificationToken,
          'password': password,
          'lang': _languageCode(),
          'platform':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      ),
    );
    return response.data['token'] as String;
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
          'lang': _languageCode(),
          'platform':
              defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        },
      ),
    );
    return response.data['token'] as String;
  }

  Future<void> updateLanguage({required String lang}) async {
    await _send(
      () => _dio.patch(
        ApiEndpoints.language,
        data: {'lang': lang},
      ),
    );
  }

  Future<void> syncCurrentLanguage() => updateLanguage(lang: _languageCode());

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
  return AuthApi(
    ref.watch(dioProvider),
    ref.watch(languageCodeProvider),
  );
});
