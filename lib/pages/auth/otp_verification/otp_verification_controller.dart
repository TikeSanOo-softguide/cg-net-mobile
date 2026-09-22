import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class OtpVerificationState {
  const OtpVerificationState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  OtpVerificationState copyWith({bool? isLoading, String? error}) {
    return OtpVerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OtpVerificationController extends StateNotifier<OtpVerificationState> {
  OtpVerificationController(this._dio, this._secureStorage)
      : super(const OtpVerificationState());

  final Dio _dio;
  final SecureStorage _secureStorage;

  Future<bool> verify({required String challengeId, required String code}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'challenge_id': challengeId, 'code': code},
      );
      final token = response.data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw StateError('Missing authentication token');
      }
      await _secureStorage.writeToken(token);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _message(error));
      return false;
    }
  }

  Future<String?> resend(String phone) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _dio.post(
        ApiEndpoints.resendOtp,
        data: {'phone': phone},
      );
      final challengeId = response.data['challenge_id'] as String?;
      if (challengeId == null || challengeId.isEmpty) {
        throw StateError('Missing OTP challenge ID');
      }
      state = state.copyWith(isLoading: false);
      return challengeId;
    } catch (error) {
      state = state.copyWith(isLoading: false, error: _message(error));
      return null;
    }
  }

  String _message(Object error) {
    if (error is DioException) {
      final message = error.response?.data is Map
          ? error.response?.data['message'] as String?
          : null;
      return message ?? 'Unable to verify OTP.';
    }
    return 'Unable to verify OTP.';
  }
}

final otpVerificationControllerProvider =
    StateNotifierProvider<OtpVerificationController, OtpVerificationState>(
        (ref) {
  return OtpVerificationController(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});
