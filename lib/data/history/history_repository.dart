import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../models/history_model/history_model.dart';

class HistoryRepository {
  HistoryRepository(this._dio);

  final Dio _dio;

  Future<List<HistoryModel>> fetch({
    String? type,
    CancelToken? cancelToken,
  }) async {
    final normalizedType = type?.trim();
    if (normalizedType != null && normalizedType.isEmpty) {
      throw ArgumentError.value(type, 'type', 'Must not be empty.');
    }

    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.transactions,
        queryParameters: normalizedType == null
            ? null
            : {'type': normalizedType},
        cancelToken: cancelToken,
      );

      final items = _responseItems(response.data);
      return items
          .whereType<Map>()
          .where(
            (item) => normalizedType == null ||
                item['type']?.toString().trim().toLowerCase() ==
                    normalizedType.toLowerCase(),
          )
          .map(
            (item) => HistoryModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<dynamic> _responseItems(Object? responseData) {
    if (responseData is List) return responseData;
    if (responseData is Map && responseData['data'] is List) {
      return responseData['data'] as List;
    }
    throw const ApiException(ApiFailure.unknown);
  }
}

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(dioProvider));
});
