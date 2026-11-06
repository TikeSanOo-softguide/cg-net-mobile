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
}

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository(ref.watch(dioProvider));
});

final homePromotionsProvider = FutureProvider<List<HomePromotion>>((ref) {
  return ref.watch(promotionRepositoryProvider).fetchActive();
});
