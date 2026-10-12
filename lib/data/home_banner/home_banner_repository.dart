import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/utils/image_url_helper.dart';
import '../../models/advertisement_model/advertisement_model.dart';
import '../banner/banner_response_helper.dart';

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

final homeBannerProvider =
    FutureProvider.family<List<BannerModel>, String>((ref, language) async {
  final repository = ref.watch(homeBannerRepositoryProvider);

  return repository.fetchBanners(language);
});
