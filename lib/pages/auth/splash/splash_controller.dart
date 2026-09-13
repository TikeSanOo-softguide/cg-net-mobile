import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class SplashController extends StateNotifier<AsyncValue<void>> {
  SplashController(this._secureStorage) : super(const AsyncValue.data(null));

  final SecureStorage _secureStorage;

  Future<void> bootstrap(BuildContext context) async {
    if (!context.mounted) return;

    final hasToken = await _secureStorage.hasToken();
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
}

final splashControllerProvider =
    StateNotifierProvider<SplashController, AsyncValue<void>>((ref) {
  return SplashController(ref.watch(secureStorageProvider));
});
