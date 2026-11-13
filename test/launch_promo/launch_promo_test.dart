import 'dart:typed_data';

import 'package:cg_net_mobile/core/locale/app_locale_provider.dart';
import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/home_banner/home_banner_repository.dart';
import 'package:cg_net_mobile/data/launch_promo/launch_promo_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late LaunchPromoRepository repository;
  late _JsonAdapter adapter;

  setUp(() {
    adapter = _JsonAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = adapter;
    repository = LaunchPromoRepository(dio);
  });

  tearDown(() => dio.close());

  test('fetchBannerAssets returns all launch and home banner types', () async {
    final assets = await repository.fetchBannerAssets('my');

    expect(assets.skipTimerPromo?.image,
        'https://images.example.test/skip-myanmar');
    expect(assets.activeAdvertisements, hasLength(2));
    expect(
      assets.homeBanners.map((banner) => banner.image),
      ['https://images.example.test/banner'],
    );
    expect(adapter.requestCount, 1);
  });

  test('banner providers share one API request', () async {
    final container = ProviderContainer(
      overrides: [
        appLocaleProvider.overrideWith((ref) => 'en'),
        launchPromoRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await Future.wait<Object?>([
      container.read(skipTimerPromoProvider.future),
      container.read(activeAdvertisementProvider.future),
      container.read(homeBannerProvider('en').future),
    ]);

    expect(adapter.requestCount, 1);
  });

  test('fetchSkipTimerPromo returns the first usable app entry promo',
      () async {
    final promo = await repository.fetchSkipTimerPromo('my');

    expect(promo, isNotNull);
    expect(promo!.image, 'https://images.example.test/skip-myanmar');
    expect(promo.durationSeconds, 8);
  });

  test('fetchSkipTimerPromo uses the default duration', () async {
    _setResponse(dio, '''
      {
        "data": [
          {
            "type": "app_entry",
            "image_url_en": "https://images.example.test/skip"
          }
        ]
      }
    ''');

    final promo = await repository.fetchSkipTimerPromo('en');

    expect(promo?.durationSeconds, 5);
  });

  test('fetchSkipTimerPromo returns null when no usable promo exists',
      () async {
    _setResponse(dio, '''
      {
        "data": [
          {"type": "app_entry"},
          {
            "type": "web_background",
            "image_url_en": "https://images.example.test/banner"
          }
        ]
      }
    ''');

    expect(await repository.fetchSkipTimerPromo('en'), isNull);
  });

  test('fetchActiveAdvertisement filters types and preserves API order',
      () async {
    final advertisements = await repository.fetchActiveAdvertisement('en');

    expect(
      advertisements.map((advertisement) => advertisement.image),
      [
        'https://images.example.test/ad-second',
        'https://images.example.test/ad-first',
      ],
    );
  });

  test('fetchActiveAdvertisement returns an empty list for an invalid shape',
      () async {
    _setResponse(dio, '{"data": null}');

    expect(await repository.fetchActiveAdvertisement('en'), isEmpty);
  });

  test('fetchActiveAdvertisement converts Dio errors to ApiException',
      () async {
    _setResponse(dio, '{"message":"Server error"}', statusCode: 500);

    await expectLater(
      repository.fetchActiveAdvertisement('en'),
      throwsA(
        isA<ApiException>().having(
          (error) => error.failure,
          'failure',
          ApiFailure.server,
        ),
      ),
    );
  });
}

void _setResponse(
  Dio dio,
  String body, {
  int statusCode = 200,
}) {
  dio.httpClientAdapter = _JsonAdapter(body: body, statusCode: statusCode);
}

class _JsonAdapter implements HttpClientAdapter {
  _JsonAdapter({
    String? body,
    this.statusCode = 200,
  }) : body = body ?? _promoResponse;

  final String body;
  final int statusCode;
  int requestCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
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

const _promoResponse = '''
{
  "data": [
    {
      "id": 1,
      "type": "app_popup",
      "sort_order": 20,
      "image_url_en": "https://images.example.test/ad-second"
    },
    {
      "id": 2,
      "type": "app_entry",
      "sort_order": 7,
      "image_url_my": "https://images.example.test/skip-myanmar",
      "duration": 8
    },
    {
      "id": 3,
      "type": "app_popup",
      "sort_order": 1,
      "image_url_en": "https://images.example.test/ad-first"
    },
    {
      "id": 4,
      "type": "app_entry",
      "sort_order": 1,
      "image_url_en": "https://images.example.test/skip-english",
      "duration": 2
    },
    {
      "id": 5,
      "type": "web_background",
      "image_url_en": "https://images.example.test/banner"
    }
  ]
}
''';
