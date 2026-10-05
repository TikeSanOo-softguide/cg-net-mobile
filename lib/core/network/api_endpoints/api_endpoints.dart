class ApiEndpoints {
  ApiEndpoints._();

  static const _env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const _override = String.fromEnvironment('API_BASE_URL');

  /// Dev expects `adb reverse tcp:8080 tcp:8080` so 127.0.0.1 reaches the
  /// host on both real devices and emulators. Staging and production must
  /// pass `API_BASE_URL` (HTTPS) with `--dart-define`.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return switch (_env) {
      'dev' => 'http://127.0.0.1:8080/api',
      _ => throw StateError(
          'Set --dart-define=API_BASE_URL=https://... for APP_ENV=$_env',
        ),
    };
  }

  static const String requestOtp = '/auth/register/request-otp';
  static const String verifyOtp = '/auth/register/verify-otp';
  static const String completeRegistration = '/auth/register/complete';
  static const String login = '/auth/login';
  static const String inbox = '/inbox';
  static const String deviceTokens = '/device-tokens';
  static const String availablePlans = '/web-app/packages';
  static const String profile = '/user';
}
