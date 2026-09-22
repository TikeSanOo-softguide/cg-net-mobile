import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/dio_client/dio_client.dart';

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
  final String? error;

  LoginState copyWith({
    CountryDial? country,
    bool? isLoading,
    bool? acceptedTerms,
    String? error,
  }) {
    return LoginState(
      country: country ?? this.country,
      isLoading: isLoading ?? this.isLoading,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      error: error,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._dio) : super(const LoginState());

  final Dio _dio;

  void setCountry(CountryDial country) {
    state = state.copyWith(country: country);
  }

  void setAcceptedTerms(bool value) {
    state = state.copyWith(acceptedTerms: value);
  }

  Future<String?> submit(String rawPhone) async {
    if (!state.acceptedTerms) return null;
    state = state.copyWith(isLoading: true);
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final full = '${state.country.dialCode}$digits';
    try {
      final response = await _dio.post(
        ApiEndpoints.sendOtp,
        data: {'phone': full},
      );
      final challengeId = response.data['challenge_id'] as String?;
      if (challengeId == null || challengeId.isEmpty) {
        throw StateError('Missing OTP challenge ID');
      }
      state = state.copyWith(isLoading: false);
      return '$full|$challengeId';
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
      return message ?? 'Unable to send OTP.';
    }
    return 'Unable to send OTP.';
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(dioProvider));
});
