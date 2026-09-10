import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/app_locale_provider.dart';
import '../../../core/storage/local_prefs/local_prefs.dart';

class LanguageSettingsController extends StateNotifier<String> {
  LanguageSettingsController(this._ref, this._localPrefs)
      : super(_localPrefs.languageCode ?? 'en');

  final Ref _ref;
  final LocalPrefs _localPrefs;

  Future<void> change(BuildContext context, String code) async {
    if (state == code && context.locale.languageCode == code) return;

    state = code;
    await _localPrefs.setLanguageCode(code);

    final locale = switch (code) {
      'my' => const Locale('my'),
      'zh' => const Locale('zh'),
      _ => const Locale('en'),
    };

    await context.setLocale(locale);
    _ref.read(appLocaleProvider.notifier).state = code;

    if (!context.mounted) return;
    state = context.locale.languageCode;
  }
}

final languageSettingsControllerProvider =
    StateNotifierProvider<LanguageSettingsController, String>((ref) {
  return LanguageSettingsController(
    ref,
    ref.watch(localPrefsProvider),
  );
});
