class ApiEndpoints {
  ApiEndpoints._();

  static const _env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const _override =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Real-phone LAN default. Emulator should override with
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8080/api`.
  /// PC localhost / USB `adb reverse` can use
  /// `--dart-define=API_BASE_URL=http://127.0.0.1:8080/api`.
  static const _devBaseUrl = String.fromEnvironment(
    'DEV_API_BASE_URL',
    defaultValue: 'http://192.168.10.203:8080/api',
  );
  static const _healthOverride =
      String.fromEnvironment('API_HEALTHCHECK_PATH', defaultValue: '');

  /// API base URL resolution policy:
  /// 1) `API_BASE_URL` always wins when provided.
  /// 2) In `APP_ENV=dev`, fallback to `DEV_API_BASE_URL`.
  /// 3) For non-dev envs, fail fast until `API_BASE_URL` is supplied.
  ///
  /// Example:
  /// `flutter run --dart-define=API_BASE_URL=https://api.example.com/api`
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return switch (_env) {
      'dev' => _devBaseUrl,
      _ => throw StateError(
          'Set --dart-define=API_BASE_URL=https://.../api for APP_ENV=$_env',
        ),
    };
  }

  static const String requestOtp = '/auth/otp/request';
  static const String verifyOtp = '/auth/otp/verify';
  static const String completeRegistration = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String inbox = '/inbox';
  static const String deviceTokens = '/device-tokens';
  static const String availablePlans = '/web-app/packages';
  static const String banners = '/web-app/banners';
  static const String packagesBuy = '/packages/buy';
  static const String redeemCheckSerialNo = '/redeem/check-serial-no';
  static const String redeemTopUpAccount = '/redeem/top-up-account';
  static const String broadbandBind = '/broadband-account/bind';
  static const String broadbandUnbind = '/broadband-account/unbind';
  static const String profile = '/user';

  /// Override with:
  /// --dart-define=API_HEALTHCHECK_PATH=/health
  static String get healthCheckPath =>
      _healthOverride.isNotEmpty ? _healthOverride : availablePlans;
}
