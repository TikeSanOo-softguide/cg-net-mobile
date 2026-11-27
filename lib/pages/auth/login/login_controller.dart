import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/utils/device_id_service.dart';
import '../../../core/utils/phone_number.dart';

enum CountryDial {
  myanmar('+95', '🇲🇲'),
  thailand('+66', '🇹🇭'),
  china('+86', '🇨🇳');

  const CountryDial(this.dialCode, this.flag);
  final String dialCode;
  final String flag;

  String get dialCodeDigits => dialCode.replaceAll(RegExp(r'\D'), '');

  static CountryDial? fromPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    for (final country in values) {
      final prefix = country.dialCodeDigits;
      if (digits.startsWith(prefix) && digits.length > prefix.length) {
        return country;
      }
    }

    return null;
  }
}

class LoginState {
  const LoginState({
    this.country = CountryDial.myanmar,
    this.isLoading = false,
    this.error,
  });

  final CountryDial country;
  final bool isLoading;
  final ApiException? error;

  LoginState copyWith({
    CountryDial? country,
    bool? isLoading,
    ApiException? error,
    bool clearError = false,
  }) {
    return LoginState(
      country: country ?? this.country,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LoginSessionCheck {
  const LoginSessionCheck({
    required this.phone,
    required this.showAlert,
    this.deviceName,
    this.code,
    this.level,
  });

  final String phone;
  final bool showAlert;
  final String? deviceName;
  final String? code;
  final String? level;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._authApi, this._deviceIdService)
      : super(const LoginState());

  final AuthApi _authApi;
  final DeviceIdService _deviceIdService;
  String? challengeId;
  String? debugOtp;
  int resendAfter = 60;

  void setCountry(CountryDial country) {
    state = state.copyWith(country: country);
  }

  Future<LoginSessionCheck?> checkSession(String rawPhone) async {
    final apiPhone = PhoneNumber.toApiPhone(
      dialCode: state.country.dialCode,
      localInput: rawPhone,
    );
    if (state.isLoading) return null;
    if (apiPhone == null) {
      state = state.copyWith(error: const ApiException(ApiFailure.validation));
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final deviceId = await _deviceIdService.getDeviceId();
      final result = await _authApi.checkPhoneSession(
        apiPhone,
        deviceId: deviceId,
      );
      if (kDebugMode) {
        final deviceIdType = deviceId.split(':').first;
        debugPrint(
          'device_id=$deviceIdType:<redacted> '
          'showAlert=${result.showAlert} '
          'code=${result.code} device=${result.deviceName}',
        );
      }
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return LoginSessionCheck(
        phone: apiPhone,
        showAlert: result.showAlert,
        deviceName: result.deviceName,
        code: result.code,
        level: result.level,
      );
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

  Future<String?> submit(String rawPhone) async {
    final apiPhone = PhoneNumber.toApiPhone(
      dialCode: state.country.dialCode,
      localInput: rawPhone,
    );
    if (apiPhone == null) return null;

    return requestOtp(apiPhone);
  }

  Future<String?> requestOtp(String apiPhone) async {
    if (state.isLoading) return null;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authApi.requestOtp(apiPhone);
      challengeId = result.challengeId;
      debugOtp = result.debugOtp;
      resendAfter = result.resendAfter;
      if (!mounted) return apiPhone;
      state = state.copyWith(isLoading: false);
      return apiPhone;
    } on ApiException catch (error) {
      challengeId = null;
      debugOtp = null;
      if (!mounted) return null;
      state = state.copyWith(
        isLoading: false,
        error: error.failure == ApiFailure.cancelled ? null : error,
      );
      if (error.failure == ApiFailure.cancelled) return null;
      return null;
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(
    ref.watch(authApiProvider),
    ref.watch(deviceIdServiceProvider),
  );
});
