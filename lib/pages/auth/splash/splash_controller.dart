import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/push/push_notification_service.dart';
import '../../../core/router/route_names/route_names.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class SplashController extends StateNotifier<AsyncValue<void>> {
  SplashController(this._secureStorage, this._authApi, this._push)
      : super(const AsyncValue.data(null));

  final SecureStorage _secureStorage;
  final AuthApi _authApi;
  final PushNotificationService _push;

  Future<void> bootstrap(BuildContext context) async {
    if (!context.mounted) return;

    final storedToken = await _secureStorage.hasToken();
    final sessionValid = storedToken ? await _sessionIsValid() : false;
    final hasToken = storedToken && sessionValid != false;

    final onboardingDone = await _secureStorage.isOnboardingDone();

    if (!context.mounted) return;
    if (hasToken) {
      _push.activateAuthenticatedSession();
    }
    final openInbox = _push.completeSessionBootstrap(authenticated: hasToken);
    if (openInbox) {
      context.goNamed(RouteNames.inboxList);
      return;
    }

    if (hasToken) {
      context.goNamed(RouteNames.skipTimerImage);
    } else if (onboardingDone) {
      context.goNamed(RouteNames.login);
    } else {
      context.goNamed(RouteNames.onboarding);
    }
  }

  /// Only a 401 ends the session; being offline keeps the user signed in.
  Future<bool?> _sessionIsValid() async {
    try {
      await _authApi.checkSession();
      return true;
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.unauthorized) return false;
      return null;
    }
  }
}

final splashControllerProvider =
    StateNotifierProvider<SplashController, AsyncValue<void>>((ref) {
  return SplashController(
    ref.watch(secureStorageProvider),
    ref.watch(authApiProvider),
    ref.watch(pushNotificationServiceProvider),
  );
});

final skipSplashIntroProvider = StateProvider<bool>((ref) => false);
