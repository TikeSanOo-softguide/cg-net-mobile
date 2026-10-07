import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error_text.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class PasswordLoginState {
  const PasswordLoginState({this.isLoading = false, this.error});

  final bool isLoading;
  final ApiException? error;

  PasswordLoginState copyWith({
    bool? isLoading,
    ApiException? error,
    bool clearError = false,
  }) {
    return PasswordLoginState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PasswordLoginController extends StateNotifier<PasswordLoginState> {
  PasswordLoginController(this._authApi, this._secureStorage, this._push)
      : super(const PasswordLoginState());

  final AuthApi _authApi;
  final SecureStorage _secureStorage;
  final PushNotificationService _push;

  Future<bool> submit({
    required String verificationToken,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _authApi.loginWithPassword(
        verificationToken: verificationToken,
        password: password,
      );
      await _secureStorage.writeToken(token);
      _push.syncToken();
      if (!mounted) return true;
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (error) {
      if (!mounted || error.failure == ApiFailure.cancelled) return false;
      state = state.copyWith(isLoading: false, error: error);
      return false;
    }
  }

  static String localizedError(ApiException? error) {
    if (error == null) return 'password_login.invalid'.tr();
    switch (error.failure) {
      case ApiFailure.validation:
      case ApiFailure.unauthorized:
        return 'password_login.invalid'.tr();
      case ApiFailure.tooManyRequests:
        return 'api.too_many_requests'.tr();
      case ApiFailure.offline:
      case ApiFailure.timeout:
      case ApiFailure.server:
      case ApiFailure.unknown:
      case ApiFailure.cancelled:
        return apiErrorOrFallback(error);
    }
  }
}

final passwordLoginControllerProvider =
    StateNotifierProvider<PasswordLoginController, PasswordLoginState>((ref) {
  return PasswordLoginController(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
    ref.watch(pushNotificationServiceProvider),
  );
});
