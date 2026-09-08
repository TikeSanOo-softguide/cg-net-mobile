import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class OnboardingController extends StateNotifier<int> {
  OnboardingController(this._secureStorage) : super(0);

  final SecureStorage _secureStorage;
  final pageController = PageController();

  void setPage(int index) => state = index;

  Future<void> next(int total) async {
    if (state >= total - 1) return;
    await pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> finish(BuildContext context) async {
    await _secureStorage.setOnboardingDone(true);
    if (context.mounted) {
      context.goNamed(RouteNames.login);
    }
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, int>((ref) {
  return OnboardingController(ref.watch(secureStorageProvider));
});
