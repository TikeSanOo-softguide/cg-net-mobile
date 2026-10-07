import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';

export '../../../core/network/auth_api/auth_api.dart'
    show OtpChallengeResult, OtpVerifyResult;

class OtpVerificationState {
  const OtpVerificationState({
    this.isVerifying = false,
    this.isResending = false,
    this.error,
  });

  final bool isVerifying;
  final bool isResending;
  final ApiException? error;

  bool get isBusy => isVerifying || isResending;

  OtpVerificationState copyWith({
    bool? isVerifying,
    bool? isResending,
    ApiException? error,
    bool clearError = false,
  }) {
    return OtpVerificationState(
      isVerifying: isVerifying ?? this.isVerifying,
      isResending: isResending ?? this.isResending,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class OtpVerificationController extends StateNotifier<OtpVerificationState> {
  OtpVerificationController(this._authApi)
      : super(const OtpVerificationState());

  final AuthApi _authApi;

  Future<OtpVerifyResult?> verify({
    required String challengeId,
    required String code,
  }) async {
    if (state.isBusy) return null;

    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final result = await _authApi.verifyOtp(
        challengeId: challengeId,
        code: code,
      );
      if (!mounted) return result;
      state = state.copyWith(isVerifying: false);
      return result;
    } on ApiException catch (error) {
      if (!mounted || error.failure == ApiFailure.cancelled) return null;
      state = state.copyWith(isVerifying: false, error: error);
      return null;
    }
  }

  Future<OtpChallengeResult?> resend(String phone) async {
    if (state.isBusy) return null;

    state = state.copyWith(isResending: true, clearError: true);
    try {
      final result = await _authApi.requestOtp(phone);
      if (!mounted) return result;
      state = state.copyWith(isResending: false);
      return result;
    } on ApiException catch (error) {
      if (!mounted || error.failure == ApiFailure.cancelled) return null;
      state = state.copyWith(isResending: false, error: error);
      return null;
    }
  }

  /// Localized message for verify / resend failures (EN / MY / ZH).
  static String localizedError(ApiException? error) {
    if (error == null) return 'otp.invalid'.tr();

    switch (error.failure) {
      case ApiFailure.offline:
      case ApiFailure.timeout:
      case ApiFailure.server:
      case ApiFailure.unknown:
      case ApiFailure.cancelled:
      case ApiFailure.unauthorized:
        return apiErrorOrFallback(error);
      case ApiFailure.tooManyRequests:
        return 'api.too_many_requests'.tr();
      case ApiFailure.validation:
        final detail = error.detail?.toLowerCase() ?? '';
        if (detail.contains('expired')) {
          return 'otp.expired'.tr();
        }
        return 'otp.invalid'.tr();
    }
  }

  static int? retryAfterSeconds(ApiException? error) {
    if (error == null || error.failure != ApiFailure.tooManyRequests) {
      return null;
    }
    return int.tryParse(error.detail ?? '');
  }
}

final otpVerificationControllerProvider =
    StateNotifierProvider<OtpVerificationController, OtpVerificationState>(
        (ref) {
  return OtpVerificationController(ref.watch(authApiProvider));
});
