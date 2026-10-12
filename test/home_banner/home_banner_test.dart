import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/home_banner/home_banner_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;
  late HomeBannerRepository repository;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api'))
      ..httpClientAdapter = _JsonAdapter();
    repository = HomeBannerRepository(dio);
  });

  tearDown(() => dio.close());

  test('fetches only web backgrounds and preserves API order', () async {
    final banners = await repository.fetchBanners('my');

    expect(
      banners.map((banner) => banner.image),
      [
        'https://images.example.test/my-first',
        'https://images.example.test/en-fallback',
        'https://images.example.test/my-last',
      ],
    );
  });

  test('accepts a top-level list response', () async {
    _setResponse(dio, '''
      [
        {
          "type": "web_background",
          "image_url_en": "https://images.example.test/banner"
        }
      ]
    ''');

    final banners = await repository.fetchBanners('en');

    expect(banners, hasLength(1));
    expect(banners.single.image, 'https://images.example.test/banner');
  });

  test('returns an empty list for an unsupported response shape', () async {
    _setResponse(dio, '{"data": {"items": []}}');

    expect(await repository.fetchBanners('en'), isEmpty);
  });

  test('converts Dio server errors to ApiException', () async {
    _setResponse(dio, '{"message":"Server error"}', statusCode: 500);

    await expectLater(
      repository.fetchBanners('en'),
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
  }) : body = body ?? _bannerResponse;

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

const _bannerResponse = '''
{
  "data": [
    {
      "id": 10,
      "type": "web_background",
      "sort_order": 20,
      "image_url_my": "https://images.example.test/my-first",
      "image_url_en": "https://images.example.test/en-first"
    },
    {
      "id": 11,
      "type": "app_entry",
      "sort_order": 1,
      "image_url_my": "https://images.example.test/skip-promo"
    },
    {
      "id": 12,
      "type": "web_background",
      "sort_order": 1,
      "image_url_en": "https://images.example.test/en-fallback"
    },
    {
      "id": 13,
      "type": "web_background",
      "sort_order": 3
    },
    {
      "id": 14,
      "type": "web_background",
      "sort_order": 0,
      "image_url_my": "https://images.example.test/my-last"
    }
  ]
}
''';
