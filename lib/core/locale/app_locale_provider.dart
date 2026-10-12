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

/// Auth title: 18 default, −2 for Myanmar / Chinese.
double authTitleFontSize(BuildContext context) =>
    usesCompactAuthType(context) ? 16 : 18;

/// Auth subtitle: 15 default, −1 for Myanmar / Chinese.
double authSubtitleFontSize(BuildContext context) =>
    usesCompactAuthType(context) ? 14 : 15;

/// OTP resend / countdown: 15 English, 14 Myanmar / Chinese.
double otpResendFontSize(BuildContext context) =>
    usesCompactAuthType(context) ? 14 : 15;
