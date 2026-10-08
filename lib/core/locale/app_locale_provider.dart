import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/local_prefs/local_prefs.dart';

/// Current app language code (`en` / `my` / `zh`).
/// Bump/watch this so shell tabs refresh translations immediately.
final appLocaleProvider = StateProvider<String>((ref) {
  return ref.watch(localPrefsProvider).languageCode ?? 'en';
});

bool isMyanmarLocale(BuildContext context) =>
    context.locale.languageCode == 'my';

bool isChineseLocale(BuildContext context) =>
    context.locale.languageCode == 'zh';

/// Compact title/subtitle sizing for Myanmar and Chinese.
bool usesCompactAuthType(BuildContext context) =>
    isMyanmarLocale(context) || isChineseLocale(context);

/// Auth title: 20 default, −2 for Myanmar / Chinese.
double authTitleFontSize(BuildContext context) =>
    usesCompactAuthType(context) ? 18 : 20;

/// Auth subtitle: 16 default, −1 for Myanmar / Chinese.
double authSubtitleFontSize(BuildContext context) =>
    usesCompactAuthType(context) ? 15 : 16;

/// OTP resend / countdown: 16 base → EN/ZH −1, Myanmar −2.
double otpResendFontSize(BuildContext context) {
  final code = context.locale.languageCode;
  if (code == 'my') return 14;
  return 15; // en, zh, and others
}
