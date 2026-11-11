import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/network/auth_api/auth_api.dart';
import 'package:cg_net_mobile/core/push/push_notification_service.dart';
import 'package:cg_net_mobile/core/router/route_names/route_names.dart';
import 'package:cg_net_mobile/core/storage/secure_storage/secure_storage.dart';
import 'package:cg_net_mobile/components/app_button/app_button.dart';
import 'package:cg_net_mobile/pages/auth/otp_success/otp_success_page.dart';
import 'package:cg_net_mobile/pages/auth/otp_verification/otp_verification_page.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
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

  group('OTP verification flow', () {
    testWidgets('routes each OTP result and recovers from malformed steps',
        (tester) async {
      final flow = await _pumpOtpFlow(
        tester,
        const OtpVerifyResult(
          nextStep: 'register',
          verificationToken: 'registration-token',
        ),
      );

      await _verifyAndContinue(tester, flow);

      expect(flow.router.routeInformationProvider.value.uri.path,
          RoutePaths.setUsernamePassword);
      expect(
        flow.router.routeInformationProvider.value.uri.queryParameters,
        {
          'phone': '+959123456789',
          'verification_token': 'registration-token',
        },
      );

      flow.authApi.result = const OtpVerifyResult(
        nextStep: 'password',
        verificationToken: 'password-token',
      );
      flow.router.go(_otpLocation);
      await tester.pumpAndSettle();
      await _verifyAndContinue(tester, flow);

      expect(flow.router.routeInformationProvider.value.uri.path,
          RoutePaths.passwordLogin);
      expect(
        flow.router.routeInformationProvider.value.uri.queryParameters,
        {
          'phone': '+959123456789',
          'verification_token': 'password-token',
        },
      );

      flow.authApi.result = const OtpVerifyResult(
        nextStep: 'authenticated',
        accessToken: 'access-token',
      );
      flow.router.go(_otpLocation);
      await tester.pumpAndSettle();
      await _verifyAndContinue(tester, flow);

      expect(
          flow.router.routeInformationProvider.value.uri.path, RoutePaths.home);
      expect(flow.storage.writtenTokens, ['access-token']);
      expect(flow.push.syncCalls, 1);
      expect(flow.authApi.syncLanguageCalls, 1);
      flow.storage.writtenTokens.clear();

      final invalidSteps = [
        const OtpVerifyResult(nextStep: 'register'),
        const OtpVerifyResult(nextStep: 'password'),
        const OtpVerifyResult(nextStep: 'authenticated'),
        const OtpVerifyResult(
          nextStep: 'unsupported',
          verificationToken: 'unexpected-token',
        ),
      ];
      for (final result in invalidSteps) {
        flow.authApi.result = result;
        flow.router.go(_otpLocation);
        await tester.pumpAndSettle();
        await _verifyAndContinue(tester, flow);

        expect(
            find.text('Your number was verified, but we couldn\'t continue. '
                'Please return to login and try again.'),
            findsOneWidget);
        await tester.tap(find.text('Return to login'));
        await _pumpTransientUi(tester);

        expect(flow.router.routeInformationProvider.value.uri.path,
            RoutePaths.login);
        expect(flow.storage.writtenTokens, isEmpty);
      }
    });

    testWidgets(
        'legacy OTP-success route forwards only with verification '
        'state', (tester) async {
      final router = _testRouter(
        initialLocation: Uri(
          path: RoutePaths.otpSuccess,
          queryParameters: {
            'phone': '+959123456789',
            'verification_token': 'legacy-token',
          },
        ).toString(),
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => child!,
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path,
          RoutePaths.setUsernamePassword);
      expect(
        router.routeInformationProvider.value.uri.queryParameters,
        {
          'phone': '+959123456789',
          'verification_token': 'legacy-token',
        },
      );
      router.dispose();
    });

    testWidgets('legacy OTP-success route without token returns to login',
        (tester) async {
      final router = _testRouter(
        initialLocation: '${RoutePaths.otpSuccess}?phone=%2B959123456789',
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          builder: (_, child) => child!,
        ),
      );
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, RoutePaths.login);
      router.dispose();
    });
  });

  group('OTP verification API response parsing', () {
    test('rejects a response without next_step', () async {
      final api = _authApiWithResponse(const {});

      await expectLater(
        api.verifyOtp(challengeId: 'challenge', code: '123456'),
        throwsA(isA<ApiException>()),
      );
    });

    test('rejects a non-object response', () async {
      final api = _authApiWithResponse('unexpected');

      await expectLater(
        api.verifyOtp(challengeId: 'challenge', code: '123456'),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

const _otpLocation =
    '${RoutePaths.otpVerification}?phone=%2B959123456789&challenge_id=challenge';

Future<_OtpFlowHarness> _pumpOtpFlow(
  WidgetTester tester,
  OtpVerifyResult result,
) async {
  final authApi = _TestAuthApi(result);
  final storage = _TestSecureStorage();
  final push = _TestPushNotificationService();
  final container = ProviderContainer(
    overrides: [
      authApiProvider.overrideWithValue(authApi),
      secureStorageProvider.overrideWithValue(storage),
      pushNotificationServiceProvider.overrideWithValue(push),
    ],
  );
  final router = _testRouter(
    initialLocation: _otpLocation,
  );
  addTearDown(router.dispose);
  addTearDown(container.dispose);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('my'), Locale('zh')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: UncontrolledProviderScope(
        container: container,
        child: Builder(
          builder: (context) => MaterialApp.router(
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            routerConfig: router,
            builder: EasyLoading.init(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _OtpFlowHarness(
    router: router,
    storage: storage,
    push: push,
    authApi: authApi,
  );
}

Future<void> _verifyAndContinue(
  WidgetTester tester,
  _OtpFlowHarness flow,
) async {
  final otpFields = find.byType(TextField);
  expect(otpFields, findsNWidgets(6));
  for (var index = 0; index < 6; index++) {
    await tester.enterText(otpFields.at(index), '${index + 1}');
    await tester.pump();
  }
  expect(
    tester.widget<AppButton>(find.byType(AppButton)).onPressed,
    isNotNull,
    reason: 'Verify should become enabled after all six digits are entered.',
  );
  flow.authApi.verifyCalls = 0;
  await tester.tap(find.text('Verify'));
  for (var attempt = 0;
      attempt < 20 && flow.authApi.verifyCalls == 0;
      attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 500));
  expect(flow.authApi.verifyCalls, 1);
  await tester.tap(find.text('Continue'));
  await _pumpTransientUi(tester);
}

Future<void> _pumpTransientUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

GoRouter _testRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: RoutePaths.otpVerification,
        name: RouteNames.otpVerification,
        builder: (context, state) => OtpVerificationPage(
          phone: state.uri.queryParameters['phone'] ?? '',
          challengeId: state.uri.queryParameters['challenge_id'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.otpSuccess,
        name: RouteNames.otpSuccess,
        builder: (context, state) => OtpSuccessPage(
          phone: state.uri.queryParameters['phone'] ?? '',
          verificationToken:
              state.uri.queryParameters['verification_token'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.setUsernamePassword,
        name: RouteNames.setUsernamePassword,
        builder: (_, __) => const Text('Registration setup'),
      ),
      GoRoute(
        path: RoutePaths.passwordLogin,
        name: RouteNames.passwordLogin,
        builder: (_, __) => const Text('Password login'),
      ),
      GoRoute(
        path: RoutePaths.home,
        name: RouteNames.home,
        builder: (_, __) => const Text('Home'),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (_, __) => const Text('Login'),
      ),
    ],
  );
}

AuthApi _authApiWithResponse(Object? responseData) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: responseData,
          ),
        );
      },
    ),
  );
  return AuthApi(dio, () => 'en');
}

class _OtpFlowHarness {
  const _OtpFlowHarness({
    required this.router,
    required this.storage,
    required this.push,
    required this.authApi,
  });

  final GoRouter router;
  final _TestSecureStorage storage;
  final _TestPushNotificationService push;
  final _TestAuthApi authApi;
}

class _TestAuthApi extends AuthApi {
  _TestAuthApi(this.result) : super(Dio(), () => 'en');

  OtpVerifyResult result;
  int syncLanguageCalls = 0;
  int verifyCalls = 0;

  @override
  Future<OtpVerifyResult> verifyOtp({
    required String challengeId,
    required String code,
  }) async {
    verifyCalls++;
    expect(challengeId, 'challenge');
    expect(code, '123456');
    return result;
  }

  @override
  Future<void> syncCurrentLanguage() async {
    syncLanguageCalls++;
  }
}

class _TestSecureStorage implements SecureStorage {
  final writtenTokens = <String>[];

  @override
  Future<void> writeToken(String token) async {
    writtenTokens.add(token);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestPushNotificationService implements PushNotificationService {
  int syncCalls = 0;

  @override
  Future<void> syncToken() async {
    syncCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
