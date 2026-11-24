import 'package:cg_net_mobile/core/utils/banner_response_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/storage/local_prefs/local_prefs.dart';
import '../../core/utils/image_url_helper.dart';
import '../../models/advertisement_model/advertisement_model.dart';
import '../launch_promo/launch_promo_repository.dart';
import 'home_banner_cache.dart';

class HomeBannerRepository {
  HomeBannerRepository(this._dio);

  final Dio _dio;

  Future<List<BannerModel>> fetchBanners(String language) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.banners,
      );

      final banners = <BannerModel>[];
      for (final item in BannerResponseHelper.itemsOfType(
        response.data,
        type: 'web_background',
      )) {
        final imageUrl = ImageUrlHelper.resolve(
          item,
          language: language,
        );

        if (imageUrl != null && imageUrl.isNotEmpty) {
          banners.add(BannerModel(
            image: imageUrl,
          ));
        }
      }

      return banners;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final homeBannerRepositoryProvider = Provider<HomeBannerRepository>((ref) {
  return HomeBannerRepository(
    ref.watch(dioProvider),
  );
});

/// Null only in tests that check the shared banner request and skip disk cache.
final homeBannerCacheStoreProvider = Provider<HomeBannerCache?>((ref) {
  return HomeBannerCache(
    preferences: ref.watch(sharedPreferencesProvider),
    cacheDirectory: getApplicationCacheDirectory,
  );
});

/// Last banner photos saved on this phone for one language.
final homeBannerDiskProvider =
    FutureProvider.family<List<BannerModel>, String>((ref, language) async {
  final store = ref.watch(homeBannerCacheStoreProvider);
  if (store == null) return const [];
  return store.read(language);
});

final homeBannerProvider =
    FutureProvider.family<List<BannerModel>, String>((ref, language) async {
  final store = ref.watch(homeBannerCacheStoreProvider);
  try {
    final assets = await ref.watch(launchBannerAssetsProvider(language).future);
    if (store == null) return assets.homeBanners;
    final stored = await store.write(language, assets.homeBanners);
    ref.invalidate(homeBannerDiskProvider(language));
    return stored;
  } catch (error, stackTrace) {
    if (store != null) {
      final cached = await store.read(language);
      if (cached.isNotEmpty) return cached;
    }
    Error.throwWithStackTrace(error, stackTrace);
  }
});
