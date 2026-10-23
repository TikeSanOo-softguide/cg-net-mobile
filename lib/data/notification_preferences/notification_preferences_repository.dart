import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../models/notification_preferences_model/notification_preferences_model.dart';

class NotificationPreferencesRepository {
  NotificationPreferencesRepository(this._dio);

  final Dio _dio;

  Future<NotificationPreferencesModel> fetch() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.notificationPreferences,
      );
      var data = _asMap(response.data);
      if (data['data'] is Map) {
        data = _asMap(data['data']);
      }
      if (data['preferences'] is Map) {
        data = _asMap(data['preferences']);
      }
      if (data.isEmpty) {
        throw const FormatException(
          'Notification preferences response is not an object.',
        );
      }
      return NotificationPreferencesModel.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<void> update(NotificationPreferencesModel preferences) async {
    try {
      await _dio.patch<dynamic>(
        ApiEndpoints.notificationPreferences,
        data: preferences.toJson(),
      );
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return const {};
  }
}

final notificationPreferencesRepositoryProvider =
    Provider<NotificationPreferencesRepository>((ref) {
  return NotificationPreferencesRepository(ref.watch(dioProvider));
});
