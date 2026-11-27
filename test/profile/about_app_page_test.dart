import 'package:cg_net_mobile/components/app_card/app_card.dart';
import 'package:cg_net_mobile/components/app_refresh_indicator/app_refresh_indicator.dart';
import 'package:cg_net_mobile/core/locale/app_locale_provider.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/theme/app_style/app_style.dart';
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
  testWidgets('renders release notes, empty state, and retries real errors',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith((ref) => 'en'),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'ChenGuang',
            packageName: 'com.example.yno',
            version: '1.2.3',
            buildNumber: '4',
          ),
        ),
        _testAppVersionInfoProvider.overrideWith(
          (ref) => _versionInfo(releaseNotesEn: 'Test release notes'),
        ),
        _testAppVersionErrorProvider.overrideWith((ref) => null),
        aboutAppVersionProvider.overrideWith((ref) async {
          final error = ref.watch(_testAppVersionErrorProvider);
          if (error != null) throw error;
          return ref.watch(_testAppVersionInfoProvider);
        }),
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

    container.read(_testAppVersionInfoProvider.notifier).state =
        _versionInfo(releaseNotesEn: '');
    await container.read(aboutAppVersionProvider.future);
    await tester.pumpAndSettle();

    expect(find.text('No release notes yet'), findsOneWidget);
    expect(
      find.text('Release notes will appear here when available.'),
      findsOneWidget,
    );
    final iconFinder = find.byIcon(Icons.description_outlined);
    expect(iconFinder, findsOneWidget);
    expect(tester.widget<Icon>(iconFinder).size, 36);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(AppRefreshIndicator), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    final emptyCardFinder = find.ancestor(
      of: find.text('No release notes yet'),
      matching: find.byType(AppCard),
    );
    expect(emptyCardFinder, findsOneWidget);
    final emptyCard = tester.widget<AppCard>(emptyCardFinder);
    expect(emptyCard.elevated, isFalse);
    expect(emptyCard.bordered, isFalse);
    expect(emptyCard.padding, const EdgeInsets.all(AppStyle.spaceXxl));
    final colorFilteredFinder = find.ancestor(
      of: iconFinder,
      matching: find.byType(ColorFiltered),
    );
    expect(colorFilteredFinder, findsOneWidget);
    expect(
      tester.widget<ColorFiltered>(colorFilteredFinder).colorFilter,
      const ColorFilter.mode(Color(0xFFDA0C81), BlendMode.srcIn),
    );

    const error = ApiException(ApiFailure.server);
    container.read(_testAppVersionErrorProvider.notifier).state = error;
    await expectLater(
      container.read(aboutAppVersionProvider.future),
      throwsA(same(error)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextButton), findsOneWidget);
    expect(find.text('No release notes yet'), findsNothing);
  });
}

final _testAppVersionInfoProvider =
    StateProvider<AppVersionInfo>((ref) => _versionInfo());
final _testAppVersionErrorProvider = StateProvider<Object?>((ref) => null);

AppVersionInfo _versionInfo({String releaseNotesEn = ''}) {
  return AppVersionInfo(
    platform: 'android',
    version: '2.0.0',
    minimumVersion: '1.5.0',
    downloadUrl: 'https://example.com/download',
    releaseNotesEn: releaseNotesEn,
    releaseNotesZh: '',
    releaseNotesMy: '',
    forceUpdate: false,
    createdAt: null,
  );
}
