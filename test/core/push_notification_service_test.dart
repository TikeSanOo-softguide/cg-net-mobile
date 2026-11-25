import 'package:cg_net_mobile/core/push/push_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defers a notification Inbox navigation until session bootstrap', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final push = container.read(pushNotificationServiceProvider);

    push.openInbox();

    expect(push.completeSessionBootstrap(authenticated: true), isTrue);
  });

  test('discards a notification Inbox navigation when signed out', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final push = container.read(pushNotificationServiceProvider);

    push.openInbox();

    expect(push.completeSessionBootstrap(authenticated: false), isFalse);
    expect(push.completeSessionBootstrap(authenticated: true), isFalse);
  });
}
