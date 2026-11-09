import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../models/promotion_model/promotion_model.dart';

class PromotionRepository {
  PromotionRepository(this._dio);

  final Dio _dio;

  Future<List<HomePromotion>> fetchActive() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.promotions);
      final data = response.data;
      final list = data is Map && data['data'] is List
          ? data['data'] as List
          : data is List
              ? data
              : const [];
      return list
          .whereType<Map>()
          .map(
            (item) => HomePromotion.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.hasContent)
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<HomePromotion> fetchOne(String idOrSlug) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.promotion(idOrSlug),
      );
      final data = response.data;
      final map = data is Map && data['data'] is Map
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};
      final item = HomePromotion.fromJson(map);
      if (!item.hasContent) {
        throw const ApiException(ApiFailure.unknown);
      }
      return item;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository(ref.watch(dioProvider));
});

final homePromotionsProvider = FutureProvider<List<HomePromotion>>((ref) {
  return ref.watch(promotionRepositoryProvider).fetchActive();
});

String? promotionCatalogId(String id) {
  const prefix = 'promotion-';
  final trimmed = id.trim();
  if (!trimmed.startsWith(prefix)) return null;
  final key = trimmed.substring(prefix.length).trim();
  return key.isEmpty ? null : key;
}

final promotionDetailProvider =
    FutureProvider.family<HomePromotion, String>((ref, idOrSlug) async {
  final listed = ref.watch(homePromotionsProvider).valueOrNull;
  if (listed != null) {
    for (final item in listed) {
      if (item.id == idOrSlug || item.slug == idOrSlug) {
        return item;
      }
    }
  }
  return ref.watch(promotionRepositoryProvider).fetchOne(idOrSlug);
});
