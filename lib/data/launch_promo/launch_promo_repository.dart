import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale/app_locale_provider.dart';
import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/utils/image_url_helper.dart';
import '../../models/advertisement_model/advertisement_model.dart';

class LaunchPromoRepository {
  LaunchPromoRepository(this._dio);

  final Dio _dio;

  Future<SkipTimerPromo?> fetchSkipTimerPromo(
    String language,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.banners,
      );

      final data = response.data;

      final List list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      } else {
        return null;
      }

      final entryBanners = list.where(
        (item) =>
            item is Map &&
            (item['type'] == 'app_entry'),
      );

      for (final item in entryBanners) {
        if (item is! Map) continue;

        final imageUrl = ImageUrlHelper.resolve(
          item,
          language: language,
        );

        if (imageUrl != null && imageUrl.isNotEmpty) {
          return SkipTimerPromo(
            image: imageUrl,
            durationSeconds: (item['duration'] as num?)?.toInt() ?? 5,
          );
        }
      }

      return null;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<SkipTimerPromo?> fetchActiveAdvertisement(
    String language,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.banners,
      );

      final data = response.data;

      final List list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      } else {
        return null;
      }

      final popUpsBanners = list.where(
        (item) =>
            item is Map &&
            (item['type'] == 'app_popup'),
      );

      for (final item in popUpsBanners) {
        if (item is! Map) continue;

        final imageUrl = ImageUrlHelper.resolve(
          item,
          language: language,
        );

        if (imageUrl != null && imageUrl.isNotEmpty) {
          return SkipTimerPromo(
            image: imageUrl,
            durationSeconds: (item['duration'] as num?)?.toInt() ?? 5,
          );
        }
      }

      return null;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final launchPromoRepositoryProvider = Provider<LaunchPromoRepository>((ref) {
  return LaunchPromoRepository(
    ref.watch(dioProvider),
  );
});

final skipTimerPromoProvider = FutureProvider<SkipTimerPromo?>((ref) {
  final language = ref.watch(appLocaleProvider);
  return ref.watch(launchPromoRepositoryProvider).fetchSkipTimerPromo(language);
});

final activeAdvertisementProvider = FutureProvider<SkipTimerPromo?>((ref) {
  final language = ref.watch(appLocaleProvider);
  return ref
      .watch(launchPromoRepositoryProvider)
      .fetchActiveAdvertisement(language);
});

/// When true, [HomePage] presents launch notice + promotion modals once after open.
final pendingLaunchPromotionProvider = StateProvider<bool>((ref) => false);
