import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'components/glass_notification_banner/glass_notification_banner.dart';
import 'core/network/network_recovery_controller.dart';
import 'core/push/push_notification_service.dart';
import 'core/router/app_router/app_router.dart';
import 'core/storage/local_prefs/local_prefs.dart';
import 'core/theme/app_theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.systemOverlayPrimary);
  await EasyLocalization.ensureInitialized();
  await PushNotificationService.initializeFirebase();

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

class CgNetApp extends ConsumerStatefulWidget {
  const CgNetApp({super.key});

  @override
  ConsumerState<CgNetApp> createState() => _CgNetAppState();
}

class _CgNetAppState extends ConsumerState<CgNetApp> {
  @override
  void initState() {
    super.initState();
    ref.read(pushNotificationServiceProvider).start();
    // Keep lightweight reconnect polling ready for queued retry actions.
    ref.read(networkRecoveryControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'YNO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) => GlassNotificationHost(
        onTap: ref.read(pushNotificationServiceProvider).openInbox,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
