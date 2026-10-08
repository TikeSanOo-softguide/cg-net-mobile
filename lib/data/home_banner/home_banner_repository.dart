import 'package:cg_net_mobile/core/utils/image_url_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class HomeBannerRepository {
  HomeBannerRepository(this._dio);

  final Dio _dio;

  Future<List<String>> fetchBannerImages(String language) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.banners,
      );

      final data = response.data;

      if (data is! Map || data['data'] is! List) {
        return [];
      }

      final list = data['data'] as List;

      final backgrounds = list
          .where(
            (item) => item is Map && item['type'] == 'web_background',
          )
          .toList();

      final banners = <String>[];

      for (final item in backgrounds) {
        if (item is! Map) continue;

        final imageUrl = ImageUrlHelper.resolve(
          item,
          language: language,
        );
        if (imageUrl != null && imageUrl.isNotEmpty) {
          banners.add(imageUrl);
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

final homeBannerProvider =
    FutureProvider.family<List<String>, String>((ref, language) async {
  final repository = ref.watch(homeBannerRepositoryProvider);

  return repository.fetchBannerImages(language);
});
