import 'dart:async';
import 'dart:io';

import 'package:cg_net_mobile/components/network_status_host/network_status_host.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/network/backend_probe.dart';
import 'package:cg_net_mobile/core/network/internet_reachability.dart';
import 'package:cg_net_mobile/core/network/network_monitor.dart';
import 'package:cg_net_mobile/core/network/network_status.dart';
import 'package:cg_net_mobile/core/network/offline_navigation.dart';
import 'package:cg_net_mobile/core/network/server_availability.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late FakeLinks links;
  late FakeReachability reachability;

  setUp(() {
    links = FakeLinks();
    reachability = FakeReachability();
    NetworkStatusSnapshot.update(NetworkStatus.checking);
    BackendStatusSnapshot.update(BackendStatus.unknown);
  });

  NetworkMonitor monitor({
    void Function()? onRecovered,
    BackendProbe? backend,
  }) {
    return NetworkMonitor(
      links: links,
      reachability: reachability,
      backend: backend,
      onRecovered: onRecovered,
      debounce: Duration.zero,
    );
  }

  test('Wi-Fi disconnected is offline without a reachability probe', () async {
    links.now = const [ConnectivityResult.none];
    final active = monitor();
    addTearDown(active.dispose);
    await active.start();
    expect(active.state, NetworkStatus.offline);
    expect(reachability.calls, 0);
  });

  test('mobile data disconnected is offline', () async {
    links.now = const [ConnectivityResult.mobile];
    reachability.result = Reachability.internet;
    final active = monitor();
    addTearDown(active.dispose);
    await active.start();
    expect(active.state, NetworkStatus.online);

    links.now = const [ConnectivityResult.none];
    await active.recheck();
    expect(active.state, NetworkStatus.offline);
  });

  test('Wi-Fi without internet is offline', () async {
    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.noInternet;
    final active = monitor();
    addTearDown(active.dispose);
    await active.start();
    expect(active.state, NetworkStatus.offline);
    expect(reachability.calls, 1);
  });

  test('internet restored notifies once and runs recovery', () async {
    links.now = const [ConnectivityResult.none];
    var recovered = 0;
    final active = monitor(onRecovered: () => recovered++);
    addTearDown(active.dispose);
    await active.start();
    expect(active.state, NetworkStatus.offline);

    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.internet;
    await active.recheck();
    expect(active.state, NetworkStatus.online);
    expect(recovered, 1);

    await active.recheck();
    expect(recovered, 1);
  });

  test('resume rechecks the current link and reachability', () async {
    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.noInternet;
    final active = monitor();
    addTearDown(active.dispose);
    await active.start();
    expect(active.state, NetworkStatus.offline);

    reachability.result = Reachability.internet;
    await active.recheck();
    expect(links.checks, 2);
    expect(active.state, NetworkStatus.online);
  });

  test('repeated offline states do not notify again', () async {
    links.now = const [ConnectivityResult.none];
    final active = monitor();
    addTearDown(active.dispose);
    var notices = 0;
    active.addListener((_) => notices++, fireImmediately: false);
    await active.start();
    await active.recheck();
    expect(active.state, NetworkStatus.offline);
    expect(notices, 1);
  });

  test('public targets are not the Chen Guang API host', () {
    expect(
      publicReachabilityTargets.any((target) => target.host == '192.168.100.178'),
      isFalse,
    );
    expect(reachabilityTargets(), publicReachabilityTargets);
  });

  test('connection refused on a public target still counts as internet', () async {
    final checker = SocketInternetReachability(
      targets: const [ReachabilityTarget('192.0.2.1', 9)],
      connector: (host, port, timeout) async {
        throw const SocketException('Connection refused');
      },
    );
    expect(await checker.check(), Reachability.internet);
  });

  test('one failed public target does not force offline', () async {
    final checker = SocketInternetReachability(
      targets: const [
        ReachabilityTarget('203.0.113.1', 443),
        ReachabilityTarget('203.0.113.2', 443),
      ],
      connector: (host, port, timeout) async {
        if (host.endsWith('.1')) throw TimeoutException('timed out');
        throw const SocketException('Connection refused');
      },
    );
    expect(await checker.check(), Reachability.internet);
  });

  test('every public target failing is offline without DNS', () async {
    final checker = SocketInternetReachability(
      targets: const [ReachabilityTarget('203.0.113.1', 443)],
      connector: (host, port, timeout) async {
        throw TimeoutException('timed out');
      },
    );
    expect(await checker.check(), Reachability.noInternet);
  });

  test('API refusal is unavailable and does not change internet status', () async {
    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.internet;
    final backend = FakeBackend()..result = BackendStatus.unavailable;
    final active = monitor(backend: backend);
    addTearDown(active.dispose);
    await active.start();
    expect(active.state, NetworkStatus.online);
    expect(active.backendStatus, BackendStatus.unavailable);
    expect(backend.calls, 1);
    expect(shouldPresentAsOffline(const ApiException(ApiFailure.server)), isFalse);
  });

  test('no radio does not probe the API host', () async {
    links.now = const [ConnectivityResult.none];
    final backend = FakeBackend();
    final active = monitor(backend: backend);
    addTearDown(active.dispose);
    await active.start();
    expect(active.state, NetworkStatus.offline);
    expect(active.backendStatus, BackendStatus.unknown);
    expect(backend.calls, 0);
  });

  test('connect timeout while online is server unavailable', () {
    NetworkStatusSnapshot.update(NetworkStatus.online);
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/customer/profile'),
        type: DioExceptionType.connectionTimeout,
      ),
    );
    expect(error.failure, ApiFailure.server);
    expect(error.connectionFailed, isTrue);
    expect(shouldPresentAsOffline(error), isFalse);
  });

  test('receive timeout stays a timeout', () {
    NetworkStatusSnapshot.update(NetworkStatus.online);
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/customer/profile'),
        type: DioExceptionType.receiveTimeout,
      ),
    );
    expect(error.failure, ApiFailure.timeout);
    expect(error.connectionFailed, isFalse);
    expect(shouldPresentAsOffline(error), isFalse);
  });

  test('server error stays a server failure while internet works', () {
    NetworkStatusSnapshot.update(NetworkStatus.online);
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/customer/profile'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/customer/profile'),
          statusCode: 503,
        ),
      ),
    );
    expect(error.failure, ApiFailure.server);
    expect(shouldPresentAsOffline(error), isFalse);
  });

  test('connect failure during a confirmed offline state uses the offline notice', () {
    NetworkStatusSnapshot.update(NetworkStatus.offline);
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/customer/profile'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(error.failure, ApiFailure.offline);
    expect(shouldPresentAsOffline(error), isTrue);
  });

  test('notice policy shows offline once and back online only after it', () {
    final policy = NetworkNoticePolicy();
    expect(policy.onStatus(NetworkStatus.checking), NetworkNotice.none);
    expect(policy.onStatus(NetworkStatus.online), NetworkNotice.none);
    expect(policy.onStatus(NetworkStatus.offline), NetworkNotice.offline);
    expect(policy.onStatus(NetworkStatus.offline), NetworkNotice.none);
    expect(policy.onStatus(NetworkStatus.online), NetworkNotice.backOnline);
    expect(policy.onStatus(NetworkStatus.online), NetworkNotice.none);
  });

  testWidgets('global notice shows the offline lines and clears when online',
      (tester) async {
    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.noInternet;
    final active = monitor();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          overrides: [
            networkMonitorProvider.overrideWith((ref) => active),
          ],
          child: const _HostApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await active.start();
    await tester.pump();

    expect(
      find.text(
        "No internet connection. Please check your connection and try again.",
      ),
      findsOneWidget,
    );
    await active.recheck();
    await tester.pump();
    expect(
      find.text(
        "No internet connection. Please check your connection and try again.",
      ),
      findsOneWidget,
    );

    reachability.result = Reachability.internet;
    await active.recheck();
    await tester.pump();
    expect(
      find.text(
        "No internet connection. Please check your connection and try again.",
      ),
      findsNothing,
    );
    expect(
      find.text('Your internet connection has been restored.'),
      findsOneWidget,
    );
  });

  testWidgets('global notice waits until login or home', (tester) async {
    const offline =
        'No internet connection. Please check your connection and try again.';
    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.noInternet;
    final active = monitor();
    addTearDown(active.dispose);
    final router = _launchRouter();
    addTearDown(router.dispose);
    final generation = ValueNotifier<int>(0);
    addTearDown(generation.dispose);

    await tester.pumpWidget(_routedHost(router, active, generation));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await active.start();
    await tester.pump();
    expect(find.text(offline), findsNothing);

    router.go('/onboarding');
    await tester.pump();
    expect(find.text(offline), findsNothing);

    router.go('/login');
    await tester.pump();
    expect(find.text(offline), findsOneWidget);

    router.go('/splash');
    generation.value = 1;
    await tester.pump();
    expect(find.text(offline), findsNothing);

    router.go('/launch/skip-timer');
    await tester.pump();
    expect(find.text(offline), findsNothing);

    router.go('/home');
    await tester.pump();
    expect(find.text(offline), findsOneWidget);
  });

  test('server restored follows an unavailable probe', () async {
    final notices = <ServerNotice>[];
    void onNotice(ServerNotice notice) => notices.add(notice);
    GlobalServerNotice.register(onNotice);
    addTearDown(() => GlobalServerNotice.unregister(onNotice));

    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.internet;
    final backend = FakeBackend()..result = BackendStatus.unavailable;
    final active = monitor(backend: backend);
    addTearDown(active.dispose);

    await active.start();
    expect(notices, [ServerNotice.down]);

    backend.result = BackendStatus.available;
    await active.recheck();
    expect(notices, [ServerNotice.down, ServerNotice.restored]);
  });

  test('coming online from unknown is not server restored', () async {
    final notices = <ServerNotice>[];
    void onNotice(ServerNotice notice) => notices.add(notice);
    GlobalServerNotice.register(onNotice);
    addTearDown(() => GlobalServerNotice.unregister(onNotice));

    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.internet;
    final active = monitor(
      backend: FakeBackend()..result = BackendStatus.available,
    );
    addTearDown(active.dispose);

    await active.start();
    expect(active.backendStatus, BackendStatus.available);
    expect(notices, isEmpty);
  });

  testWidgets('server notice follows the API host', (tester) async {
    links.now = const [ConnectivityResult.wifi];
    reachability.result = Reachability.internet;
    final backend = FakeBackend()..result = BackendStatus.unavailable;
    final active = monitor(backend: backend);
    addTearDown(active.dispose);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        assetLoader: const _NoticeAssetLoader(),
        saveLocale: false,
        child: ProviderScope(
          overrides: [
            networkMonitorProvider.overrideWith((ref) => active),
          ],
          child: const _HostApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await active.start();
    await tester.pump();

    expect(
      find.text('Unable to connect to the server. Please try again.'),
      findsOneWidget,
    );

    backend.result = BackendStatus.available;
    await active.recheck();
    await tester.pump();
    expect(find.text('The server is available again.'), findsOneWidget);
    expect(
      find.text('Your internet connection has been restored.'),
      findsNothing,
    );
  });
}

class _NoticeAssetLoader extends AssetLoader {
  const _NoticeAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    return const {
      'shared': {
        'offline_notice':
            'No internet connection. Please check your connection and try again.',
        'back_online_notice':
            'Your internet connection has been restored.',
        'server_down_notice':
            'Unable to connect to the server. Please try again.',
        'server_restored_notice': 'The server is available again.',
      },
    };
  }
}

GoRouter _launchRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const SizedBox.shrink(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const SizedBox.shrink()),
      GoRoute(
        path: '/launch/skip-timer',
        builder: (_, __) => const SizedBox.shrink(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const SizedBox.shrink()),
    ],
  );
}

Widget _routedHost(
  GoRouter router,
  NetworkMonitor active,
  ValueNotifier<int> generation,
) {
  return EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    assetLoader: const _NoticeAssetLoader(),
    saveLocale: false,
    child: ProviderScope(
      overrides: [
        networkMonitorProvider.overrideWith((ref) => active),
      ],
      child: ValueListenableBuilder<int>(
        valueListenable: generation,
        builder: (context, gen, _) => MaterialApp.router(
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          routerConfig: router,
          builder: (context, child) => NetworkStatusHost(
            key: ValueKey(gen),
            router: router,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

class _HostApp extends StatelessWidget {
  const _HostApp();

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => MaterialApp(
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        home: const NetworkStatusHost(
          child: Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
  }
}

class FakeLinks implements NetworkLinks {
  List<ConnectivityResult> now = const [ConnectivityResult.wifi];
  final StreamController<List<ConnectivityResult>> _changes =
      StreamController.broadcast();
  int checks = 0;

  void emit(List<ConnectivityResult> results) {
    now = results;
    _changes.add(results);
  }

  @override
  Stream<List<ConnectivityResult>> get changes => _changes.stream;

  @override
  Future<List<ConnectivityResult>> current() async {
    checks++;
    return now;
  }
}

class FakeReachability implements InternetReachability {
  Reachability result = Reachability.internet;
  int calls = 0;

  @override
  Future<Reachability> check() async {
    calls++;
    return result;
  }
}

class FakeBackend implements BackendProbe {
  BackendStatus result = BackendStatus.available;
  int calls = 0;

  @override
  Future<BackendStatus> check() async {
    calls++;
    return result;
  }
}
