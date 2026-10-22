import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/utils/phone_number.dart';

enum CountryDial {
  myanmar('+95', '🇲🇲'),
  thailand('+66', '🇹🇭'),
  china('+86', '🇨🇳');

  const CountryDial(this.dialCode, this.flag);
  final String dialCode;
  final String flag;
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
  });

  final String phone;
  final bool showAlert;
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._authApi) : super(const LoginState());

  final AuthApi _authApi;
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
    if (apiPhone == null || state.isLoading) return null;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authApi.checkPhoneSession(apiPhone);
      if (!mounted) return null;
      state = state.copyWith(isLoading: false);
      return LoginSessionCheck(
        phone: apiPhone,
        showAlert: result.showAlert,
      );
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
  return LoginController(ref.watch(authApiProvider));
});
