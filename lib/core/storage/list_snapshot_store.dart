import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_prefs/local_prefs.dart';

/// Last successful list for one signed-in user, or one shared directory.
class ListSnapshotStore {
  ListSnapshotStore(this._prefs);

  static const prefix = 'list_snapshot_v1:';
  static const complaint = 'complaint';
  static const relocation = 'relocation';
  static const changePlan = 'change_plan';
  static const changeWifi = 'change_wifi';
  static const installation = 'installation';
  static const serviceHistory = 'service_history';
  static const showroom = 'showroom';

  static const wifiSecretKeys = {'new_password', 'password'};

  final SharedPreferences _prefs;

  String? get _owner {
    final id = _prefs.getString(LocalPrefs.sessionUserIdKey)?.trim();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  /// `null` means this user has never stored this list.
  List<Map<String, dynamic>>? read(String feature, {bool shared = false}) {
    final owner = shared ? 'shared' : _owner;
    if (owner == null) return null;
    final raw = _prefs.getString('$prefix$feature:$owner');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String feature,
    List<Map<String, dynamic>> items, {
    bool shared = false,
    Set<String> omitKeys = const {},
  }) async {
    final owner = shared ? 'shared' : _owner;
    if (owner == null) return;
    final sanitized = [
      for (final item in items)
        {
          for (final entry in item.entries)
            if (!omitKeys.contains(entry.key)) entry.key: entry.value,
        },
    ];
    try {
      await _prefs.setString(
        '$prefix$feature:$owner',
        jsonEncode(sanitized),
      );
    } catch (_) {}
  }

  Future<void> clear() async {
    final keys = _prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList(growable: false);
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}

List<T>? decodeSnapshot<T>(
  ListSnapshotStore? store,
  String feature,
  T Function(Map<String, dynamic> json) decode, {
  bool shared = false,
}) {
  final maps = store?.read(feature, shared: shared);
  if (maps == null) return null;
  final items = <T>[];
  for (final map in maps) {
    try {
      items.add(decode(map));
    } catch (_) {}
  }
  return items;
}

final listSnapshotStoreProvider = Provider<ListSnapshotStore>((ref) {
  return ListSnapshotStore(ref.watch(sharedPreferencesProvider));
});
