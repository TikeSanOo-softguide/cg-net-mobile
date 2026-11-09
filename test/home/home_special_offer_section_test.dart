import 'package:cg_net_mobile/data/promotion/promotion_repository.dart';
import 'package:cg_net_mobile/models/promotion_model/promotion_model.dart';
import 'package:cg_net_mobile/pages/home/home/components/home_special_offer_section.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('keeps a compact card that still scales with phone width', () {
    const smallPhone = 320.0;
    const typicalPhone = 390.0;
    final small = HomeSpecialOfferSection.layoutFor(smallPhone);
    final typical = HomeSpecialOfferSection.layoutFor(typicalPhone);

    expect(small.cardWidth, lessThan(240));
    expect(small.imageHeight, lessThanOrEqualTo(136));
    expect(small.listHeight, lessThan(270));
    expect(typical.cardWidth, greaterThanOrEqualTo(small.cardWidth));
  });

  testWidgets('fits image and description on a 320-wide phone without overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('my'), Locale('zh')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            homePromotionsProvider.overrideWith(
              (ref) async => const [
                HomePromotion(
                  id: '1',
                  titles: {'en': 'Fiber weekend'},
                  descriptions: {
                    'en':
                        'Get extra speed this weekend with a special home fiber offer for new and existing users across the city this month.',
                  },
                ),
              ],
            ),
          ],
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              home: const Scaffold(body: HomeSpecialOfferSection()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Fiber weekend'), findsOneWidget);
    expect(find.textContaining('Get extra speed'), findsOneWidget);
    expect(find.text('See more'), findsOneWidget);
  });
}
