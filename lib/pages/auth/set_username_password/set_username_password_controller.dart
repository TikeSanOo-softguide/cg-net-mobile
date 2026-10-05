import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class SetUsernamePasswordState {
  const SetUsernamePasswordState({this.isLoading = false, this.error});

  final bool isLoading;
  final ApiException? error;

  SetUsernamePasswordState copyWith({
    bool? isLoading,
    ApiException? error,
    bool clearError = false,
  }) {
    return SetUsernamePasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SetUsernamePasswordController
    extends StateNotifier<SetUsernamePasswordState> {
  SetUsernamePasswordController(this._authApi, this._secureStorage, this._push)
      : super(const SetUsernamePasswordState());

  final AuthApi _authApi;
  final SecureStorage _secureStorage;
  final PushNotificationService _push;

  Future<bool> submit({
    required String verificationToken,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _authApi.completeRegistration(
        verificationToken: verificationToken,
        name: username,
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
}

final setUsernamePasswordControllerProvider = StateNotifierProvider<
    SetUsernamePasswordController, SetUsernamePasswordState>((ref) {
  return SetUsernamePasswordController(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
    ref.watch(pushNotificationServiceProvider),
  );
});
