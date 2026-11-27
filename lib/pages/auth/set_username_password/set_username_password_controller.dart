import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';
import '../../../core/utils/device_id_service.dart';

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
  SetUsernamePasswordController(
    this._authApi,
    this._secureStorage,
    this._push,
    this._deviceIdService,
  ) : super(const SetUsernamePasswordState());

  final AuthApi _authApi;
  final SecureStorage _secureStorage;
  final PushNotificationService _push;
  final DeviceIdService _deviceIdService;

  Future<RegistrationResult?> submit({
    required String verificationToken,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final deviceId = await _deviceIdService.getDeviceId();
      final result = await _authApi.completeRegistration(
        verificationToken: verificationToken,
        name: username,
        password: password,
        deviceId: deviceId,
      );
      await _secureStorage.writeToken(result.token);
      _push.activateAuthenticatedSession();
      if (!mounted) return result;
      state = state.copyWith(isLoading: false);
      return result;
    } on DeviceIdException {
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        error: const ApiException(ApiFailure.unknown),
      );
      return null;
    } on ApiException catch (error) {
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        error: error.failure == ApiFailure.cancelled ? null : error,
      );
      return null;
    }
  }
}

final setUsernamePasswordControllerProvider = StateNotifierProvider<
    SetUsernamePasswordController, SetUsernamePasswordState>((ref) {
  return SetUsernamePasswordController(
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
    ref.watch(pushNotificationServiceProvider),
    ref.watch(deviceIdServiceProvider),
  );
});
