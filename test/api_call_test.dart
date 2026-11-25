import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/core/network/auth_interceptor/auth_interceptor.dart';
import 'package:cg_net_mobile/core/network/network_status.dart';
import 'package:cg_net_mobile/core/network/idempotency_key.dart';
import 'package:cg_net_mobile/core/network/message_codes.dart';
import 'package:cg_net_mobile/core/network/session_clock.dart';
import 'package:cg_net_mobile/core/storage/secure_storage/secure_storage.dart';
import 'package:cg_net_mobile/data/push/device_token_repository.dart';
import 'package:cg_net_mobile/data/inbox/inbox_repository.dart';
import 'package:cg_net_mobile/data/top_up/top_up_repository.dart';
import 'package:cg_net_mobile/models/user_model/user_model.dart';
import 'package:cg_net_mobile/pages/home/top_up/top_up_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('explicit local logout clears an unauthorized-expiration flag', () {
    final sessionClock = SessionClock()..expire();

    sessionClock.clearAuthentication();

    expect(sessionClock.authenticated, isFalse);
    expect(sessionClock.expiredByUnauthorized, isFalse);
  });

  for (final (code, expectedKey) in [
    (MessageCodes.userDeactivated, 'msg.user_003'),
    (MessageCodes.userSuspended, 'msg.user_004'),
  ]) {
    test('$code maps to its localized session error message', () {
      final error = ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/auth/session/check'),
          response: Response(
            requestOptions: RequestOptions(path: '/auth/session/check'),
            statusCode: 403,
            data: {
              'code': code,
              'message': 'Account status prevents login.',
              'level': 'error',
              'show_alert': true,
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(error.code, code);
      expect(MessageCodes.isKnown(error.code), isTrue);
      expect(MessageCodes.locKey(error.code!), expectedKey);
    });
  }

  test('password changed code maps to its localized snackbar message', () {
    expect(MessageCodes.isKnown(MessageCodes.pwdChanged), isTrue);
    expect(MessageCodes.locKey(MessageCodes.pwdChanged), 'msg.pwd_001');
  });

  test('registration success code maps to its localized message', () {
    expect(MessageCodes.isKnown(MessageCodes.authRegistered), isTrue);
    expect(MessageCodes.locKey(MessageCodes.authRegistered), 'msg.auth_020');
  });

  test('otp verify success code maps to its localized message', () {
    expect(MessageCodes.isKnown(MessageCodes.authOtpVerified), isTrue);
    expect(MessageCodes.locKey(MessageCodes.authOtpVerified), 'msg.auth_021');
  });

  test('shared request codes map to feature-specific loc keys', () {
    expect(
      MessageCodes.featureReqKey(
        feature: 'installationApplication',
        code: MessageCodes.reqSubmitted,
        fallbackKey: 'installationApplication.req_submitted',
      ),
      'installationApplication.req_submitted',
    );
    expect(
      MessageCodes.featureReqKey(
        feature: 'changePlan',
        code: MessageCodes.reqCancelled,
        fallbackKey: 'changePlan.req_cancelled',
      ),
      'changePlan.req_cancelled',
    );
  });

  test('already-bound broadband code maps to its localized message', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/customer/broadband/bind'),
        response: Response(
          requestOptions: RequestOptions(path: '/customer/broadband/bind'),
          statusCode: 409,
          data: {
            'code': 'MSG-BB-010',
            'message': 'MSG-BB-010',
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error.code, MessageCodes.bbAlreadyBound);
    expect(MessageCodes.isKnown(error.code), isTrue);
    expect(MessageCodes.locKey(error.code!), 'msg.bb_010');
  });

  test('incorrect password validation code maps to its localized message', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/profile/password'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile/password'),
          statusCode: 422,
          data: {
            'code': 'MSG-USER-002',
            'message': 'The current password is incorrect.',
            'errors': {
              'current_password': ['The current password is incorrect.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error.failure, ApiFailure.validation);
    expect(error.code, MessageCodes.userPasswordIncorrect);
    expect(MessageCodes.isKnown(error.code), isTrue);
    expect(MessageCodes.locKey(error.code!), 'msg.user_002');
  });

  test('idempotency keys are opaque UUIDs', () {
    final first = IdempotencyKey.generate();
    final second = IdempotencyKey.generate();

    expect(first, matches(_uuidV4Pattern));
    expect(second, isNot(first));
  });

  test('top-up retries reuse the key after a connection error', () async {
    final adapter = _RetryTopUpAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = adapter;
    final controller = TopUpController(TopUpRepository(dio));
    addTearDown(controller.dispose);

    await expectLater(
      controller.submit(phone: '959123456789', pin: '1234567890123456'),
      throwsA(isA<ApiException>()),
    );
    await controller.submit(
      phone: '959123456789',
      pin: '1234567890123456',
    );

    expect(adapter.idempotencyKeys, hasLength(2));
    expect(adapter.idempotencyKeys[0], adapter.idempotencyKeys[1]);
  });

  test('connection errors become offline failures', () {
    NetworkStatusSnapshot.update(NetworkStatus.offline);
    addTearDown(() => NetworkStatusSnapshot.update(NetworkStatus.checking));
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/inbox'),
        type: DioExceptionType.connectionError,
      ),
    );

    expect(error.failure, ApiFailure.offline);
    expect(error.messageKey, 'api.offline');
  });

  test('validation errors keep the first field message', () {
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/auth/otp/request'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/otp/request'),
          statusCode: 422,
          data: {
            'message': 'The phone field is invalid.',
            'errors': {
              'phone': ['The phone field is invalid.'],
            },
          },
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error.failure, ApiFailure.validation);
    expect(error.detail, 'The phone field is invalid.');
    expect(error.statusCode, 422);
    expect(error.responseData, {
      'message': 'The phone field is invalid.',
      'errors': {
        'phone': ['The phone field is invalid.'],
      },
    });
  });

  test('bad request errors retain the backend response', () {
    final responseData = {'message': 'PIN must not exceed 16 digits.'};
    final error = ApiException.fromDio(
      DioException(
        requestOptions: RequestOptions(path: '/top-up'),
        response: Response(
          requestOptions: RequestOptions(path: '/top-up'),
          statusCode: 400,
          data: responseData,
        ),
        type: DioExceptionType.badResponse,
      ),
    );

    expect(error.failure, ApiFailure.unknown);
    expect(error.statusCode, 400);
    expect(error.detail, 'PIN must not exceed 16 digits.');
    expect(error.responseData, responseData);
  });

  test('inbox repository reads the data list', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));
    dio.httpClientAdapter = _JsonAdapter('''
      {"data":[{"id":"announcement-1","category":"announcement","title":{"en":"Hello","my":"မင်္ဂလာပါ","zh":"你好"},"body":{"en":"Body","my":"စာ","zh":"内容"},"created_at":"2026-10-02T09:00:00.000000Z","is_read":false}]}
    ''');

    final result = await InboxRepository(dio).fetch();

    expect(result.items, hasLength(1));
    expect(result.items.single.category, InboxCategory.announcement);
    expect(result.items.single.titleFor('my'), 'မင်္ဂလာပါ');
  });

  test('inbox repository reads notification read state and marks it read',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'));
    final adapter = _NotificationAdapter();
    dio.httpClientAdapter = adapter;
    final repository = InboxRepository(dio);

    final result = await repository.fetch();

    expect(adapter.paths, ['/notifications']);
    expect(result.items.single.id, '12');
    expect(result.items.single.isRead, isFalse);
    expect(result.items.single.category, InboxCategory.system);
    expect(result.items.single.titleFor('en'), 'Bill due');

    await repository.markAsRead('12');
    expect(adapter.paths.last, '/notifications/12/read');
    expect(adapter.methods.last, 'PATCH');

    await repository.fetchUnreadCount();
  });

  test('public exact, prefix, and regex paths reach transport without a token',
      () async {
    for (final path in [
      '/auth/otp/request',
      '/web-app/banners',
      '/inbox',
      '/regions/3/areas',
    ]) {
      final adapter = _AuthGuardAdapter();
      final dio = _guardedDio(
        adapter,
        _TestSecureStorage(null),
        SessionClock(),
      );

      await dio.get<dynamic>(path);

      expect(adapter.requestCount, 1, reason: path);
    }
  });

  test('relative and full URL public paths are both normalized', () async {
    final adapter = _AuthGuardAdapter();
    final dio = _guardedDio(
      adapter,
      _TestSecureStorage(null),
      SessionClock(),
    );

    await dio.get<dynamic>('/api/auth/otp/request?phone=959123456789');
    await dio.get<dynamic>(
      'http://example.test:8080/api/auth/otp/request?phone=959123456789',
    );

    expect(adapter.requestCount, 2);
  });

  test('protected paths are rejected locally without a token', () async {
    final adapter = _AuthGuardAdapter();
    final dio = _guardedDio(
      adapter,
      _TestSecureStorage(null),
      SessionClock(),
    );
    for (final path in [
      '/auth/logout',
      '/areas',
      '/notifications',
      '/customer/profile',
    ]) {
      await expectLater(
        dio.get<dynamic>(path),
        throwsA(
          isA<DioException>().having(
            (error) => ApiException.fromDio(error).failure,
            'failure',
            ApiFailure.unauthorized,
          ),
        ),
      );
    }

    expect(adapter.requestCount, 0);
  });

  test('protected path with token but unvalidated session is rejected',
      () async {
    final adapter = _AuthGuardAdapter();
    final dio = _guardedDio(
      adapter,
      _TestSecureStorage('stale-token'),
      SessionClock(),
    );

    await expectLater(
      dio.get<dynamic>('/customer/profile'),
      throwsA(
        isA<DioException>().having(
          (error) => ApiException.fromDio(error).failure,
          'failure',
          ApiFailure.unauthorized,
        ),
      ),
    );

    expect(adapter.requestCount, 0);
  });

  test('protected path with validated session reaches transport with bearer',
      () async {
    final adapter = _AuthGuardAdapter();
    final sessionClock = SessionClock()..authenticate();
    final dio = _guardedDio(
      adapter,
      _TestSecureStorage('valid-token'),
      sessionClock,
    );

    await dio.get<dynamic>('/customer/profile');

    expect(adapter.requestCount, 1);
    expect(adapter.authorizationHeaders, ['Bearer valid-token']);
  });

  test('explicit public option overrides protected defaults', () async {
    final adapter = _AuthGuardAdapter();
    final dio = _guardedDio(
      adapter,
      _TestSecureStorage(null),
      SessionClock(),
    );

    await dio.get<dynamic>(
      '/notifications',
      options: Options(extra: {AuthInterceptor.publicKey: true}),
    );

    expect(adapter.requestCount, 1);
  });

  test('explicit require-auth option overrides public routes', () async {
    final adapter = _AuthGuardAdapter();
    final dio = _guardedDio(
      adapter,
      _TestSecureStorage(null),
      SessionClock(),
    );

    await expectLater(
      dio.get<dynamic>(
        '/auth/otp/request',
        options: Options(extra: {AuthInterceptor.requireAuthKey: true}),
      ),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requestCount, 0);
  });

  test('a 401 for an old token does not clear a newly stored token', () async {
    final storage = _RotatingTokenSecureStorage('old-token');
    final adapter = _UnauthorizedAfterRotationAdapter(storage);
    var unauthorizedCallbackCalls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        AuthInterceptor(
          storage,
          SessionClock()..authenticate(),
          () => unauthorizedCallbackCalls++,
        ),
      );

    await expectLater(
      dio.get<dynamic>(
        '/protected',
      ),
      throwsA(isA<DioException>()),
    );

    expect(storage.token, 'new-token');
    expect(storage.clearCalls, 0);
    expect(unauthorizedCallbackCalls, 0);
  });

  test('device-token requests are protected by default', () async {
    final adapter = _AuthGuardAdapter();
    final dio = _guardedDio(
      adapter,
      _TestSecureStorage(null),
      SessionClock(),
    );
    final repository = DeviceTokenRepository(dio);

    await expectLater(
      repository.register('fcm-token'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.unauthorized,
        ),
      ),
    );
    await expectLater(
      repository.remove('fcm-token'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.unauthorized,
        ),
      ),
    );

    expect(adapter.requestCount, 0);
  });

  test('serial check keeps the backend response message', () async {
    final dio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"success":false,"message":"Invalid or unavailable top-up card."}',
      );

    final result = await TopUpRepository(dio).checkSerialNo('1234567890123456');

    expect(result.isValid, isFalse);
    expect(result.status, TopUpSerialCheckStatus.invalid);
    expect(result.message, 'Invalid or unavailable top-up card.');
  });

  test('serial check distinguishes an unknown card from a used card', () async {
    final invalidDio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"result":"invalid_card","message":"Invalid top-up card."}',
        statusCode: 400,
      );
    final usedDio = Dio(BaseOptions(baseUrl: 'http://example.test/api'))
      ..httpClientAdapter = _JsonAdapter(
        '{"result":"already_used","message":"This top-up card has already been used."}',
        statusCode: 400,
      );

    final invalid =
        await TopUpRepository(invalidDio).checkSerialNo('1234567890123456');
    final used =
        await TopUpRepository(usedDio).checkSerialNo('1234567890123456');

    expect(invalid.status, TopUpSerialCheckStatus.invalid);
    expect(invalid.isValid, isFalse);
    expect(used.status, TopUpSerialCheckStatus.alreadyUsed);
    expect(used.isValid, isFalse);
  });
}

Dio _guardedDio(
  HttpClientAdapter adapter,
  SecureStorage storage,
  SessionClock sessionClock,
) {
  return Dio(BaseOptions(baseUrl: 'http://example.test/api'))
    ..httpClientAdapter = adapter
    ..interceptors.add(
      AuthInterceptor(storage, sessionClock, () {}),
    );
}

final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter(this.body, {this.statusCode = 200});

  final String body;
  final int statusCode;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _RetryTopUpAdapter implements HttpClientAdapter {
  final idempotencyKeys = <String?>[];
  var _attempt = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    idempotencyKeys.add(options.headers['Idempotency-Key'] as String?);
    if (_attempt++ == 0) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }

    return ResponseBody.fromString(
      '{"success":true,"message":"Top-up successful."}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _NotificationAdapter implements HttpClientAdapter {
  final paths = <String>[];
  final methods = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    paths.add(options.path);
    methods.add(options.method);
    const body =
        '{"data":[{"id":12,"title":"Bill due","body":"Pay before Friday.","category":"bill_alert","is_read":false,"created_at":"2026-10-02T09:00:00.000000Z"}],"unread_count":1,"current_page":1,"last_page":1}';
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _AuthGuardAdapter implements HttpClientAdapter {
  int requestCount = 0;
  final authorizationHeaders = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    authorizationHeaders.add(options.headers['Authorization'] as String?);
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _TestSecureStorage implements SecureStorage {
  _TestSecureStorage(this.token);

  final String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RotatingTokenSecureStorage implements SecureStorage {
  _RotatingTokenSecureStorage(this.token);

  String? token;
  int clearCalls = 0;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> clearToken() async {
    clearCalls++;
    token = null;
  }

  @override
  Future<bool> clearTokenIfMatches(String expectedToken) async {
    if (token != expectedToken) return false;
    await clearToken();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnauthorizedAfterRotationAdapter implements HttpClientAdapter {
  _UnauthorizedAfterRotationAdapter(this.storage);

  final _RotatingTokenSecureStorage storage;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    storage.token = 'new-token';
    return ResponseBody.fromString(
      '{"message":"Unauthorized"}',
      401,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
