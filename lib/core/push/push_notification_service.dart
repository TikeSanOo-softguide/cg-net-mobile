import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/push/device_token_repository.dart';
import '../network/auth_interceptor/auth_interceptor.dart';
import '../router/app_router/app_router.dart';
import '../router/route_names/route_names.dart';
import '../storage/secure_storage/secure_storage.dart';
import 'in_app_notice.dart';

class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  bool _started = false;

  /// Must match `default_notification_channel_id` in AndroidManifest.xml.
  static const _channel = AndroidNotificationChannel(
    'cg_net_default',
    'CG-NET',
    description: 'Announcements, promotions and account updates',
    importance: Importance.high,
  );

  /// Firebase stays optional so platforms without a Firebase config file
  /// (iOS, web) still boot.
  static Future<bool> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      return true;
    } catch (error) {
      debugPrint('[push] Firebase unavailable: $error');
      return false;
    }
  }

  Future<void> start() async {
    if (_started || Firebase.apps.isEmpty) return;
    _started = true;

    // Only used to register the Android channel for background pushes;
    // foreground pushes are drawn by GlassNotificationHost.
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    _subscriptions
      ..add(FirebaseMessaging.onMessage.listen(_showForeground))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen((_) => openInbox()))
      ..add(messaging.onTokenRefresh.listen(_register));

    if (await messaging.getInitialMessage() != null) openInbox();

    await syncToken();
  }

  /// Sends the current FCM token to the backend when the user is signed in.
  Future<void> syncToken() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _register(token);
    } catch (error) {
      debugPrint('[push] token sync failed: $error');
    }
  }

  /// Call before clearing the auth token; the endpoint requires auth.
  Future<void> unregister() async {
    if (Firebase.apps.isEmpty) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _ref.read(deviceTokenRepositoryProvider).remove(token);
      }
    } catch (error) {
      debugPrint('[push] token removal failed: $error');
    }
  }

  Future<void> _register(String token) async {
    if (!await _ref.read(secureStorageProvider).hasToken()) return;
    try {
      await _ref.read(deviceTokenRepositoryProvider).register(token);
    } catch (error) {
      debugPrint('[push] token register failed: $error');
    }
  }

  void _showForeground(RemoteMessage message) {
    final language = _ref.read(languageCodeProvider)();
    final title = message.data['title_$language'] as String? ??
        message.notification?.title;
    if (title == null || title.isEmpty) return;
    final body = message.notification?.body;
    final now = DateTime.now();

    _ref.read(inAppNoticeProvider.notifier).state = InAppNotice(
      id: message.messageId ?? '${now.microsecondsSinceEpoch}',
      title: title,
      // The backend repeats the English title as the body.
      body: body == null || body == message.data['title_en'] ? null : body,
      receivedAt: now,
    );
  }

  void openInbox() {
    _ref.read(appRouterProvider).go(RoutePaths.inboxList);
  }

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }
}

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  final service = PushNotificationService(ref);
  ref.onDispose(service.dispose);
  return service;
});
