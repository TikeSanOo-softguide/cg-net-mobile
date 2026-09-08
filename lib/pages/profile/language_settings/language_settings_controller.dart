import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs/local_prefs.dart';

class LanguageSettingsController extends StateNotifier<String> {
  LanguageSettingsController(this._localPrefs)
      : super(_localPrefs.languageCode ?? 'en');

  final LocalPrefs _localPrefs;

  Future<void> change(BuildContext context, String code) async {
    state = code;
    await _localPrefs.setLanguageCode(code);
    final locale = switch (code) {
      'my' => const Locale('my'),
      'zh' => const Locale('zh'),
      _ => const Locale('en'),
    };
    await context.setLocale(locale);
  }
}

final languageSettingsControllerProvider =
    StateNotifierProvider<LanguageSettingsController, String>((ref) {
  return LanguageSettingsController(ref.watch(localPrefsProvider));
});
