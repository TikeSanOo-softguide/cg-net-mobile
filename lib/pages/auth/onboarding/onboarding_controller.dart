import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names/route_names.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class OnboardingController extends StateNotifier<int> {
  OnboardingController(this._secureStorage) : super(0) {
    _scheduleAdvance();
  }

  static const _slideCount = 3;
  static const _autoAdvance = Duration(seconds: 3);
  static const _pageDuration = Duration(milliseconds: 280);

  final SecureStorage _secureStorage;
  final pageController = PageController();
  Timer? _timer;

  void setPage(int index) {
    state = index;
    _scheduleAdvance();
  }

  Future<void> next(int total) async {
    if (state >= total - 1) return;
    await pageController.nextPage(
      duration: _pageDuration,
      curve: Curves.easeOut,
    );
  }

  Future<void> finish(BuildContext context) async {
    _timer?.cancel();
    await _secureStorage.setOnboardingDone(true);
    if (context.mounted) {
      context.goNamed(RouteNames.login);
    }
  }

  void _scheduleAdvance() {
    _timer?.cancel();
    _timer = Timer(_autoAdvance, _advanceLoop);
  }

  Future<void> _advanceLoop() async {
    if (!pageController.hasClients) {
      _scheduleAdvance();
      return;
    }
    final next = (state + 1) % _slideCount;
    if (next == 0) {
      pageController.jumpToPage(0);
    } else {
      await pageController.nextPage(
        duration: _pageDuration,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    pageController.dispose();
    super.dispose();
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, int>((ref) {
  return OnboardingController(ref.watch(secureStorageProvider));
});
