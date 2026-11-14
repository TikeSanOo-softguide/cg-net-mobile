import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/local_prefs/local_prefs.dart';

/// Last support-chat transcript. Already-received messages stay available offline.
class ChatTranscriptCache {
  ChatTranscriptCache(this._preferences);

  final SharedPreferences? _preferences;

  Map<String, dynamic>? read() {
    final raw = _preferences?.getString(LocalPrefs.chatCacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> json) async {
    await _preferences?.setString(LocalPrefs.chatCacheKey, jsonEncode(json));
  }

  Future<void> clear() async {
    await _preferences?.remove(LocalPrefs.chatCacheKey);
  }
}
