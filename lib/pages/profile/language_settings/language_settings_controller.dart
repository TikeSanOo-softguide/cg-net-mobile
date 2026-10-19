import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/app_locale_provider.dart';
import '../../../core/network/auth_api/auth_api.dart';
import '../../../core/storage/local_prefs/local_prefs.dart';
import '../../../core/storage/secure_storage/secure_storage.dart';

class LanguageSettingsController extends StateNotifier<String> {
  LanguageSettingsController(
    this._ref,
    this._localPrefs,
    this._authApi,
    this._secureStorage,
  ) : super(_localPrefs.languageCode ?? 'en');

  final Ref _ref;
  final LocalPrefs _localPrefs;
  final AuthApi _authApi;
  final SecureStorage _secureStorage;
  Future<void> _changeQueue = Future<void>.value();

  Future<void> change(BuildContext context, String code) async {
    final previous = _changeQueue;
    final completer = Completer<void>();
    _changeQueue = completer.future;
    try {
      await previous;
      if (!context.mounted) return;
      await _applyChange(context, code);
    } finally {
      completer.complete();
    }
  }

  Future<void> _applyChange(BuildContext context, String code) async {
    if (!context.mounted) return;
    if (state == code && context.locale.languageCode == code) {
      _ref.read(appLocaleProvider.notifier).state = code;
      return;
    }

    if (await _secureStorage.hasToken()) {
      await _authApi.updateLanguage(lang: code);
      if (!context.mounted) return;
    }

    await _localPrefs.setLanguageCode(code);
    if (!context.mounted) return;

    final locale = switch (code) {
      'my' => const Locale('my'),
      'zh' => const Locale('zh'),
      _ => const Locale('en'),
    };

    await context.setLocale(locale);
    _ref.read(appLocaleProvider.notifier).state = code;
    state = code;
  }
}

final languageSettingsControllerProvider =
    StateNotifierProvider<LanguageSettingsController, String>((ref) {
  return LanguageSettingsController(
    ref,
    ref.watch(localPrefsProvider),
    ref.watch(authApiProvider),
    ref.watch(secureStorageProvider),
  );
});
