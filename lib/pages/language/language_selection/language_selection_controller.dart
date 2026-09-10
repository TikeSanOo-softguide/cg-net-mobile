import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/locale/app_locale_provider.dart';
import '../../../core/storage/local_prefs/local_prefs.dart';

class LanguageSelectionState {
  const LanguageSelectionState({
    this.selectedCode,
    this.isSaving = false,
  });

  final String? selectedCode;
  final bool isSaving;

  LanguageSelectionState copyWith({
    String? selectedCode,
    bool? isSaving,
  }) {
    return LanguageSelectionState(
      selectedCode: selectedCode ?? this.selectedCode,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class LanguageSelectionController
    extends StateNotifier<LanguageSelectionState> {
  LanguageSelectionController(this._ref, this._localPrefs)
      : super(LanguageSelectionState(selectedCode: _localPrefs.languageCode));

  final Ref _ref;
  final LocalPrefs _localPrefs;

  void select(String code) {
    state = state.copyWith(selectedCode: code);
  }

  Future<void> confirm(BuildContext context) async {
    final code = state.selectedCode;
    if (code == null) return;
    state = state.copyWith(isSaving: true);
    await _localPrefs.setLanguageCode(code);
    final locale = switch (code) {
      'my' => const Locale('my'),
      'zh' => const Locale('zh'),
      _ => const Locale('en'),
    };
    await context.setLocale(locale);
    _ref.read(appLocaleProvider.notifier).state = code;
    state = state.copyWith(isSaving: false);
  }
}

final languageSelectionControllerProvider =
    StateNotifierProvider<LanguageSelectionController, LanguageSelectionState>(
        (ref) {
  return LanguageSelectionController(
    ref,
    ref.watch(localPrefsProvider),
  );
});
