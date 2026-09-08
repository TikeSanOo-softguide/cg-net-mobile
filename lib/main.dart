import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/router/app_router/app_router.dart';
import 'core/storage/local_prefs/local_prefs.dart';
import 'core/theme/app_theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final savedLanguageRaw = prefs.getString(LocalPrefs.languageKey) ?? 'en';
  final savedLanguage = savedLanguageRaw == 'mm' ? 'my' : savedLanguageRaw;

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('my'),
        Locale('zh'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: Locale(savedLanguage),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const CgNetApp(),
      ),
    ),
  );
}

class CgNetApp extends ConsumerWidget {
  const CgNetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'CG-NET',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
    );
  }
}
