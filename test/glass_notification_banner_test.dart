import 'package:cg_net_mobile/components/glass_notification_banner/glass_notification_banner.dart';
import 'package:cg_net_mobile/core/push/in_app_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<ProviderContainer> pumpHost(
    WidgetTester tester, {
    required VoidCallback onTap,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: GlassNotificationHost(
            onTap: onTap,
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      ),
    );
    return container;
  }

  InAppNotice notice(String id) => InAppNotice(
        id: id,
        title: 'New promotion',
        body: 'Double data this weekend',
        receivedAt: DateTime(2026, 10, 2, 17, 5),
      );

  testWidgets('shows the notice and opens it on tap', (tester) async {
    var taps = 0;
    final container = await pumpHost(tester, onTap: () => taps++);

    container.read(inAppNoticeProvider.notifier).state = notice('1');
    await tester.pumpAndSettle();

    expect(find.text('New promotion'), findsOneWidget);
    expect(find.text('Double data this weekend'), findsOneWidget);

    await tester.tap(find.text('New promotion'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text('New promotion'), findsNothing);
  });

  testWidgets('hides itself after the display time', (tester) async {
    final container = await pumpHost(tester, onTap: () {});

    container.read(inAppNoticeProvider.notifier).state = notice('2');
    await tester.pumpAndSettle();
    expect(find.text('New promotion'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('New promotion'), findsNothing);
    expect(container.read(inAppNoticeProvider), isNull);
  });
}
