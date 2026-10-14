import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/models/change_password_model/change_password_model.dart';
import 'package:cg_net_mobile/models/change_password_model/change_password_otp_session.dart';
import 'package:dio/dio.dart';

class ChangePasswordRepository {
  ChangePasswordRepository(this._dio);

  final Dio _dio;

  Future<ChangePasswordChallenge> changePassword({
    required ChangePasswordModel password,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.changePassword,
        data: password.toJson(),
      );
      final data = response.data;
      if (data is! Map || data['challenge_id'] is! String) {
        throw const ApiException(ApiFailure.unknown);
      }
      final challengeId = (data['challenge_id'] as String).trim();
      if (challengeId.isEmpty) {
        throw const ApiException(ApiFailure.unknown);
      }
      final debugOtp = data['debug_otp']?.toString();
      final resendAfter = _readPositiveInt(data['resend_after']) ?? 60;
      return ChangePasswordChallenge(
        challengeId: challengeId,
        debugOtp: debugOtp == null || debugOtp.isEmpty ? null : debugOtp,
        resendAfter: resendAfter,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        final retryAfter = _readPositiveInt(
              (error.response?.data as Map?)?['retry_after'],
            ) ??
            _readPositiveInt(error.response?.headers.value('retry-after'));
        throw ApiException(
          ApiFailure.tooManyRequests,
          detail: retryAfter?.toString(),
          statusCode: error.response?.statusCode,
          responseData: error.response?.data,
        );
      }
      throw ApiException.fromDio(error);
    }
  }

  Future<void> verifyOtp({
    required String challengeId,
    required String otp,
  }) async {
    try {
      await _dio.post(
        ApiEndpoints.verifyChangePasswordOtp,
        data: {
          'challenge_id': challengeId,
          'code': otp,
        },
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
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
}
