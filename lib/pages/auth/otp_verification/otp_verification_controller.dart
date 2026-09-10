import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpVerificationState {
  const OtpVerificationState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  OtpVerificationState copyWith({bool? isLoading, String? error}) {
    return OtpVerificationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OtpVerificationController extends StateNotifier<OtpVerificationState> {
  OtpVerificationController() : super(const OtpVerificationState());

  Future<bool> verify(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final ok = code.length == 4;
    state = state.copyWith(
      isLoading: false,
      error: ok ? null : 'invalid',
    );
    return ok;
  }

  Future<void> resend() async {
    state = state.copyWith(isLoading: true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isLoading: false);
  }
}

final otpVerificationControllerProvider =
    StateNotifierProvider<OtpVerificationController, OtpVerificationState>(
        (ref) {
  return OtpVerificationController();
});
