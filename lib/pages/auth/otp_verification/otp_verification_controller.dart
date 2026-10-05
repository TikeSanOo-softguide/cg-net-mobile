import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';

export '../../../core/network/auth_api/auth_api.dart' show OtpChallengeResult;

class OtpVerificationState {
  const OtpVerificationState({this.isLoading = false, this.error});

  final bool isLoading;
  final ApiException? error;

  OtpVerificationState copyWith({
    bool? isLoading,
    ApiException? error,
    bool clearError = false,
  }) {
    return OtpVerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OtpVerificationController extends StateNotifier<OtpVerificationState> {
  OtpVerificationController(this._authApi)
      : super(const OtpVerificationState());

  final AuthApi _authApi;

  Future<String?> verify({
    required String challengeId,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _authApi.verifyOtp(
        challengeId: challengeId,
        code: code,
      );
      if (!mounted) return token;
      state = state.copyWith(isLoading: false);
      return token;
    } on ApiException catch (error) {
      if (!mounted || error.failure == ApiFailure.cancelled) return null;
      state = state.copyWith(isLoading: false, error: error);
      return null;
    }
  }

  Future<OtpChallengeResult?> resend(String phone) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authApi.requestOtp(phone);
      if (!mounted) return result;
      state = state.copyWith(isLoading: false);
      return result;
    } on ApiException catch (error) {
      if (!mounted || error.failure == ApiFailure.cancelled) return null;
      state = state.copyWith(isLoading: false, error: error);
      return null;
    }
  }
}

final otpVerificationControllerProvider =
    StateNotifierProvider<OtpVerificationController, OtpVerificationState>(
        (ref) {
  return OtpVerificationController(ref.watch(authApiProvider));
});
