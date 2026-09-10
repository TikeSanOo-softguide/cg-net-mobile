import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  });

  final CountryDial country;
  final bool isLoading;
  final bool acceptedTerms;

  LoginState copyWith({
    CountryDial? country,
    bool? isLoading,
    bool? acceptedTerms,
  }) {
    return LoginState(
      country: country ?? this.country,
      isLoading: isLoading ?? this.isLoading,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController() : super(const LoginState());

  void setCountry(CountryDial country) {
    state = state.copyWith(country: country);
  }

  void setAcceptedTerms(bool value) {
    state = state.copyWith(acceptedTerms: value);
  }

  Future<String?> submit(String rawPhone) async {
    if (!state.acceptedTerms) return null;
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final full = '${state.country.dialCode}$digits';
    state = state.copyWith(isLoading: false);
    return full;
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController();
});
