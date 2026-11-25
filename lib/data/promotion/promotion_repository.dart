import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/network/offline_navigation.dart';
import '../../core/storage/local_prefs/local_prefs.dart';
import '../../models/promotion_model/promotion_model.dart';

class PromotionRepository {
  PromotionRepository(this._dio, {SharedPreferences? preferences})
      : _preferences = preferences;

  static const cacheKey = LocalPrefs.homePromotionsCacheKey;

  final Dio _dio;
  final SharedPreferences? _preferences;

  /// `null` means this phone has never stored a special-offer list.
  static List<HomePromotion>? readCached(SharedPreferences? preferences) {
    final raw = preferences?.getString(cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (item) => HomePromotion.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.hasContent)
          .toList();
    } catch (_) {
      return null;
    }
  }

  List<HomePromotion>? readCache() => readCached(_preferences);

  Future<void> saveCache(List<HomePromotion> items) async {
    await _preferences?.setString(
      cacheKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

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
  return PromotionRepository(
    ref.watch(dioProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  );
});

/// Last special-offer list saved on this phone.
final homePromotionsCacheProvider = Provider<List<HomePromotion>?>((ref) {
  return PromotionRepository.readCached(ref.watch(sharedPreferencesProvider));
});

final homePromotionsProvider = FutureProvider<List<HomePromotion>>((ref) async {
  final repository = ref.watch(promotionRepositoryProvider);
  try {
    final items = await repository.fetchActive();
    await repository.saveCache(items);
    ref.invalidate(homePromotionsCacheProvider);
    return items;
  } on ApiException catch (error) {
    if (isUnreachableError(error)) {
      final cached = repository.readCache();
      if (cached != null) return cached;
    }
    rethrow;
  }
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
