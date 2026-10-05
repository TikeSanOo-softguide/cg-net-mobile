import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';

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
    this.acceptedTerms = false,
    this.error,
  });

  final CountryDial country;
  final bool isLoading;
  final bool acceptedTerms;
  final ApiException? error;

  LoginState copyWith({
    CountryDial? country,
    bool? isLoading,
    bool? acceptedTerms,
    ApiException? error,
    bool clearError = false,
  }) {
    return LoginState(
      country: country ?? this.country,
      isLoading: isLoading ?? this.isLoading,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._authApi) : super(const LoginState());

  final AuthApi _authApi;
  String? challengeId;
  String? debugOtp;

  void setCountry(CountryDial country) {
    state = state.copyWith(country: country);
  }

  void setAcceptedTerms(bool value) {
    state = state.copyWith(acceptedTerms: value);
  }

  Future<String?> submit(String rawPhone) async {
    if (!state.acceptedTerms) return null;
    state = state.copyWith(isLoading: true, clearError: true);
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final full = '${state.country.dialCode}$digits';
    try {
      final result = await _authApi.requestOtp(full);
      challengeId = result.challengeId;
      debugOtp = result.debugOtp;
      if (!mounted) return full;
      state = state.copyWith(isLoading: false);
      return full;
    } on ApiException catch (error) {
      challengeId = null;
      debugOtp = null;
      if (!mounted || error.failure == ApiFailure.cancelled) return null;
      state = state.copyWith(isLoading: false, error: error);
      return null;
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(authApiProvider));
});
