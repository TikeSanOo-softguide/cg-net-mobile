import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_prefs/local_prefs.dart';

/// Current app language code (`en` / `my` / `zh`).
/// Bump/watch this so shell tabs refresh translations immediately.
final appLocaleProvider = StateProvider<String>((ref) {
  return ref.watch(localPrefsProvider).languageCode ?? 'en';
});
