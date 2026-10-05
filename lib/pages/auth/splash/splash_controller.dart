import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class SplashController extends StateNotifier<AsyncValue<void>> {
  SplashController(this._secureStorage, this._authApi)
      : super(const AsyncValue.data(null));

  final SecureStorage _secureStorage;
  final AuthApi _authApi;

  Future<void> bootstrap(BuildContext context) async {
    if (!context.mounted) return;

    final hasToken = await _secureStorage.hasToken() && await _sessionIsValid();
    final onboardingDone = await _secureStorage.isOnboardingDone();

    if (!context.mounted) return;
    if (hasToken) {
      context.goNamed(RouteNames.skipTimerImage);
    } else if (onboardingDone) {
      context.goNamed(RouteNames.login);
    } else {
      context.goNamed(RouteNames.onboarding);
    }
  }

  /// Only a 401 ends the session; being offline keeps the user signed in.
  Future<bool> _sessionIsValid() async {
    try {
      await _authApi.checkSession();
      return true;
    } on ApiException catch (error) {
      return error.failure != ApiFailure.unauthorized;
    }
  }
}

final splashControllerProvider =
    StateNotifierProvider<SplashController, AsyncValue<void>>((ref) {
  return SplashController(
    ref.watch(secureStorageProvider),
    ref.watch(authApiProvider),
  );
});
