import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/pages/profile/about_app/about_app_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads localized release notes from the API resource response',
      () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': [
                  {
                    'id': 1,
                    'platform': 'ios',
                    'version': '2.1.0',
                    'minimum_version': '2.0.0',
                    'download_url': 'https://example.test/download',
                    'release_notes': {
                      'en': 'English notes',
                      'zh': 'Chinese notes',
                      'my': 'Myanmar notes',
                    },
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final version = await AboutAppRepository(dio).fetchForPlatform('ios');

    expect(version.releaseNotes('en'), 'English notes');
    expect(version.releaseNotes('zh'), 'Chinese notes');
    expect(version.releaseNotes('my'), 'Myanmar notes');
  });

  test('reads a single resource object', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {'data': _record(platform: 'ios', version: '5.0.0')},
            ),
          );
        },
      ),
    );

    final version = await AboutAppRepository(dio).fetchForPlatform('ios');

    expect(version.version, '5.0.0');
    expect(version.createdAt, DateTime(2026, 1, 1));
  });

  test('selects latest active app version for the requested platform',
      () async {
    RequestOptions? requested;
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requested = options;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'data': [
                  _record(platform: 'android', version: '4.0.0'),
                  _record(
                    platform: 'IOS',
                    version: '1.0.0',
                    createdAt: '2026-01-01T00:00:00',
                  ),
                  _record(
                    platform: 'ios',
                    version: '2.0.0',
                    createdAt: '2026-02-01T00:00:00',
                  ),
                  {
                    ..._record(platform: 'ios', version: '9.0.0'),
                    'status': 'draft'
                  },
                ],
              },
            ),
          );
        },
      ),
    );

    final version = await AboutAppRepository(dio).fetchForPlatform('ios');

    expect(requested?.path, ApiEndpoints.appVersion);
    expect(version.version, '2.0.0');
    expect(version.platform, 'ios');
    expect(version.releaseNotes('my'), 'Myanmar release notes');
    expect(version.forceUpdate, isFalse);
  });
}

Map<String, Object> _record({
  required String platform,
  required String version,
  String createdAt = '2026-01-01T00:00:00',
}) {
  return {
    'platform': platform,
    'version': version,
    'minimum_version': '1.0.0',
    'download_url': 'https://example.test/download',
    'release_notes_en': 'English release notes',
    'release_notes_zh': 'Chinese release notes',
    'release_notes_my': 'Myanmar release notes',
    'force_update': false,
    'status': 'active',
    'created_at': createdAt,
  };
}
