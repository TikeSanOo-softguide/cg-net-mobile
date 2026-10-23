import 'package:cg_net_mobile/core/locale/app_locale_provider.dart';
import 'package:cg_net_mobile/core/utils/version_check/version_check.dart';
import 'package:cg_net_mobile/pages/profile/about_app/about_app_controller.dart';
import 'package:cg_net_mobile/pages/profile/about_app/about_app_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows API version details and preserves the icon credit link',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith((ref) => 'en'),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'YNO',
            packageName: 'com.example.yno',
            version: '1.2.3',
            buildNumber: '4',
          ),
        ),
        aboutAppVersionProvider.overrideWith(
          (ref) async => const AppVersionInfo(
            platform: 'android',
            version: '2.0.0',
            minimumVersion: '1.5.0',
            downloadUrl: 'https://example.com/download',
            releaseNotesEn: 'Test release notes',
            releaseNotesZh: '',
            releaseNotesMy: '',
            forceUpdate: false,
            createdAt: null,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(aboutAppVersionProvider.future);
    await container.read(packageInfoProvider.future);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('my'), Locale('zh')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: UncontrolledProviderScope(
          container: container,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: const AboutAppPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2.0.0'), findsOneWidget);
    expect(find.textContaining('1.2.3'), findsOneWidget);
    expect(find.text('Test release notes'), findsOneWidget);
    expect(find.text('Icons from Flaticon'), findsOneWidget);
    expect(find.text('Flaticon - Receipt icons'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('Flaticon - Receipt icons'),
        matching: find.byType(InkWell),
      ),
      findsOneWidget,
    );
  });
}
