import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/storage/local_prefs/local_prefs.dart';
import '../../models/user_model/user_model.dart';

class InboxRepository {
  InboxRepository(this._dio, {SharedPreferences? preferences})
      : _preferences = preferences;

  static const cacheKey = LocalPrefs.inboxCacheKey;

  final Dio _dio;
  final SharedPreferences? _preferences;

  Future<List<InboxMessageModel>> fetch({CancelToken? cancelToken}) async {
    try {
      final items = <InboxMessageModel>[];
      var page = 1;
      var lastPage = 1;
      do {
        final response = await _dio.get<dynamic>(
          ApiEndpoints.notifications,
          queryParameters: {'page': page},
          cancelToken: cancelToken,
        );
        final data = response.data;
        final list = data is Map && data['data'] is List
            ? data['data'] as List
            : const [];
        items.addAll(
          list.map(
            (item) => InboxMessageModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
        lastPage = data is Map
            ? int.tryParse('${data['last_page'] ?? 1}') ?? 1
            : 1;
        page++;
      } while (page <= lastPage && page <= 10);
      return items;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  /// `null` means this device has never stored an inbox.
  List<InboxMessageModel>? readCache() {
    final raw = _preferences?.getString(cacheKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded
          .whereType<Map>()
          .map(
            (item) => InboxMessageModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCache(List<InboxMessageModel> items) async {
    await _preferences?.setString(
      cacheKey,
      jsonEncode(items.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clearCache() async {
    await _preferences?.remove(cacheKey);
  }

  Future<void> markAsRead(String id, {CancelToken? cancelToken}) async {
    try {
      await _dio.patch<dynamic>(
        ApiEndpoints.notificationRead(id),
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(
    ref.watch(dioProvider),
    preferences: ref.watch(sharedPreferencesProvider),
  );
});
