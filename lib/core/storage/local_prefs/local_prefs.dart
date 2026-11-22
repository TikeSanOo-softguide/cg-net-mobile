import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalPrefs {
  LocalPrefs(this._prefs);

  final SharedPreferences _prefs;

  static const languageKey = 'selected_language';
  static const languageChosenKey = 'language_chosen';
  static const inboxCacheKey = 'inbox_messages_v1';
  static const inboxUnreadCountKey = 'inbox_unread_count_v1';
  static const chatCacheKey = 'support_chat_v1';
  static const sessionUserIdKey = 'session_user_id';

  Future<void> setLanguageCode(String code) async {
    await _prefs.setString(languageKey, code);
    await _prefs.setBool(languageChosenKey, true);
  }

  String? get languageCode {
    final code = _prefs.getString(languageKey);
    // Migrate legacy 'mm' code to ISO 'my' (Myanmar).
    if (code == 'mm') return 'my';
    return code;
  }

  bool get hasChosenLanguage => _prefs.getBool(languageChosenKey) ?? false;

  Future<void> setSessionUserId(String id) async {
    final userId = id.trim();
    if (userId.isEmpty) return;
    await _prefs.setString(sessionUserIdKey, userId);
  }

  Future<void> clearSessionUserId() async {
    await _prefs.remove(sessionUserIdKey);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main');
});

final localPrefsProvider = Provider<LocalPrefs>((ref) {
  return LocalPrefs(ref.watch(sharedPreferencesProvider));
});
