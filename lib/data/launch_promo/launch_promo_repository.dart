import 'package:cg_net_mobile/core/utils/banner_response_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale/app_locale_provider.dart';
import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/utils/image_url_helper.dart';
import '../../models/advertisement_model/advertisement_model.dart';

class LaunchBannerAssets {
  const LaunchBannerAssets({
    required this.skipTimerPromo,
    required this.activeAdvertisements,
    required this.homeBanners,
  });

  final SkipTimerPromo? skipTimerPromo;
  final List<Advertisement> activeAdvertisements;
  final List<BannerModel> homeBanners;
}

class LaunchPromoRepository {
  LaunchPromoRepository(this._dio);

  final Dio _dio;

  Future<LaunchBannerAssets> fetchBannerAssets(String language) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.banners,
      );

      SkipTimerPromo? skipTimerPromo;
      for (final item in BannerResponseHelper.itemsOfType(
        response.data,
        type: 'app_entry',
      )) {
        final imageUrl = ImageUrlHelper.resolve(
          item,
          language: language,
        );
        if (imageUrl != null && imageUrl.isNotEmpty) {
          skipTimerPromo = SkipTimerPromo(
            image: imageUrl,
            durationSeconds: (item['duration'] as num?)?.toInt() ?? 5,
          );
          break;
        }
      }

      final advertisements = <Advertisement>[];
      for (final item in BannerResponseHelper.itemsOfType(
        response.data,
        type: 'app_popup',
      )) {
        final imageUrl = ImageUrlHelper.resolve(
          item,
          language: language,
        );

        if (imageUrl == null || imageUrl.isEmpty) {
          continue;
        }

        advertisements.add(
          Advertisement(
            image: imageUrl,
          ),
        );
      }

      final homeBanners = <BannerModel>[];
      for (final item in BannerResponseHelper.itemsOfType(
        response.data,
        type: 'web_background',
      )) {
        final imageUrl = ImageUrlHelper.resolve(
          item,
          language: language,
        );
        if (imageUrl != null && imageUrl.isNotEmpty) {
          homeBanners.add(BannerModel(image: imageUrl));
        }
      }

      return LaunchBannerAssets(
        skipTimerPromo: skipTimerPromo,
        activeAdvertisements: advertisements,
        homeBanners: homeBanners,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SkipTimerPromo?> fetchSkipTimerPromo(String language) async {
    return (await fetchBannerAssets(language)).skipTimerPromo;
  }

  Future<List<Advertisement>> fetchActiveAdvertisement(String language) async {
    return (await fetchBannerAssets(language)).activeAdvertisements;
  }
}

final launchPromoRepositoryProvider = Provider<LaunchPromoRepository>((ref) {
  return LaunchPromoRepository(
    ref.watch(dioProvider),
  );
});

final launchBannerAssetsProvider =
    FutureProvider.family<LaunchBannerAssets, String>((ref, language) {
  return ref.watch(launchPromoRepositoryProvider).fetchBannerAssets(language);
});

final skipTimerPromoProvider = FutureProvider<SkipTimerPromo?>((ref) {
  final language = ref.watch(appLocaleProvider);
  return ref
      .watch(launchBannerAssetsProvider(language).future)
      .then((assets) => assets.skipTimerPromo);
});

final activeAdvertisementProvider = FutureProvider<List<Advertisement>>((ref) {
  final language = ref.watch(appLocaleProvider);
  return ref
      .watch(launchBannerAssetsProvider(language).future)
      .then((assets) => assets.activeAdvertisements);
});

/// When true, [HomePage] presents launch notice + promotion modals once after open.
final pendingLaunchPromotionProvider = StateProvider<bool>((ref) => false);
