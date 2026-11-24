import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_exception.dart';
import 'package:cg_net_mobile/data/home_banner/home_banner_cache.dart';
import 'package:cg_net_mobile/data/home_banner/home_banner_repository.dart';
import 'package:cg_net_mobile/models/advertisement_model/advertisement_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Dio dio;
  late HomeBannerRepository repository;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  test('saves a banner photo and skips a second download of the same url',
      () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final directory = await Directory.systemTemp.createTemp('home_banners');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    var downloads = 0;
    final images = Dio(BaseOptions(responseType: ResponseType.bytes))
      ..httpClientAdapter = _BytesAdapter(
        _png,
        onFetch: () => downloads++,
      );
    addTearDown(images.close);
    final cache = HomeBannerCache(
      preferences: preferences,
      cacheDirectory: () async => directory,
      imageClient: images,
    );

    final stored = await cache.write('en', const [
      BannerModel(image: 'https://images.example.test/banner'),
    ]);

    expect(downloads, 1);
    expect(stored, hasLength(1));
    expect(stored.single.localPath, isNotNull);
    expect(await File(stored.single.localPath!).exists(), isTrue);

    final again = await cache.write('en', const [
      BannerModel(image: 'https://images.example.test/banner'),
    ]);

    expect(downloads, 1);
    expect(again.single.localPath, stored.single.localPath);
  });

  test('keeps the saved photo when a replacement cannot be downloaded',
      () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final directory = await Directory.systemTemp.createTemp('home_banners');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final images = Dio(BaseOptions(responseType: ResponseType.bytes))
      ..httpClientAdapter = _BytesAdapter(_png);
    addTearDown(images.close);
    final cache = HomeBannerCache(
      preferences: preferences,
      cacheDirectory: () async => directory,
      imageClient: images,
    );
    await cache.write('en', const [
      BannerModel(image: 'https://images.example.test/old'),
    ]);

    images.httpClientAdapter = _FailingAdapter();
    final stored = await cache.write('en', const [
      BannerModel(image: 'https://images.example.test/new'),
    ]);

    expect(stored.single.image, 'https://images.example.test/old');
    expect(await File(stored.single.localPath!).exists(), isTrue);
  });

  test('keeps the network banner when the photo cannot be saved yet', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final directory = await Directory.systemTemp.createTemp('home_banners');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final images = Dio(BaseOptions(responseType: ResponseType.bytes))
      ..httpClientAdapter = _FailingAdapter();
    addTearDown(images.close);
    final cache = HomeBannerCache(
      preferences: preferences,
      cacheDirectory: () async => directory,
      imageClient: images,
    );

    final stored = await cache.write('en', const [
      BannerModel(image: 'https://images.example.test/banner'),
    ]);

    expect(stored.single.image, 'https://images.example.test/banner');
    expect(stored.single.localPath, isNull);
  });

  test('clears saved photos when the server returns no banners', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    final directory = await Directory.systemTemp.createTemp('home_banners');
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final images = Dio(BaseOptions(responseType: ResponseType.bytes))
      ..httpClientAdapter = _BytesAdapter(_png);
    addTearDown(images.close);
    final cache = HomeBannerCache(
      preferences: preferences,
      cacheDirectory: () async => directory,
      imageClient: images,
    );
    final stored = await cache.write('my', const [
      BannerModel(image: 'https://images.example.test/banner'),
    ]);
    final file = File(stored.single.localPath!);

    final cleared = await cache.write('my', const []);

    expect(cleared, isEmpty);
    expect(await file.exists(), isFalse);
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

class _BytesAdapter implements HttpClientAdapter {
  _BytesAdapter(this.bytes, {this.onFetch});

  final List<int> bytes;
  final void Function()? onFetch;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onFetch?.call();
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: ['image/png'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
  }

  @override
  void close({bool force = false}) {}
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

final List<int> _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

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
