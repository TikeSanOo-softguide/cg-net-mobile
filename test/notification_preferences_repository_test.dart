import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/data/notification_preferences/notification_preferences_repository.dart';
import 'package:cg_net_mobile/models/notification_preferences_model/notification_preferences_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferencesRepository', () {
    test('fetches notification preferences', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(
          200,
          '''
          {"announcements_notifications":true,"system_notifications":true,"promotion_notifications":true,"general_notifications":true}
          ''',
        );
      });

      final preferences = await NotificationPreferencesRepository(dio).fetch();

      expect(request.method, 'GET');
      expect(request.path, ApiEndpoints.notificationPreferences);
      expect(preferences.announcements, isTrue);
      expect(preferences.system, isTrue);
      expect(preferences.promotion, isTrue);
      expect(preferences.general, isTrue);
    });

    test('updates all preference values', () async {
      late RequestOptions request;
      final dio = _dio((options) {
        request = options;
        return _jsonResponse(200, '{}');
      });
      const preferences = NotificationPreferencesModel(
        announcements: false,
        system: true,
        promotion: true,
        general: false,
      );

      await NotificationPreferencesRepository(dio).update(preferences);

      expect(request.method, 'PATCH');
      expect(request.path, ApiEndpoints.notificationPreferences);
      expect(request.data, {
        'announcements_notifications': false,
        'system_notifications': true,
        'promotion_notifications': true,
        'general_notifications': false,
      });
    });
  });
}

Dio _dio(ResponseBody Function(RequestOptions options) respond) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'));
  dio.httpClientAdapter = _ResponseAdapter(respond);
  return dio;
}

ResponseBody _jsonResponse(int statusCode, String body) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
