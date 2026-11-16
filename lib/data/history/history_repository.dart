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
  }) {
    return _load(
      path: ApiEndpoints.transactions,
      type: type,
      cancelToken: cancelToken,
    );
  }

  Future<List<HistoryModel>> fetchService({
    CancelToken? cancelToken,
  }) {
    return _load(
      path: ApiEndpoints.internetBillHistory,
      cancelToken: cancelToken,
    );
  }

  Future<HistoryModel> fetchById(
    String id, {
    CancelToken? cancelToken,
  }) {
    return _loadOne(
      path: ApiEndpoints.transactionDetail(_requiredId(id)),
      cancelToken: cancelToken,
    );
  }

  Future<HistoryModel> fetchServiceById(
    String id, {
    CancelToken? cancelToken,
  }) {
    return _loadOne(
      path: ApiEndpoints.internetBillHistoryDetail(_requiredId(id)),
      cancelToken: cancelToken,
    );
  }

  String _requiredId(String id) {
    final historyId = id.trim();
    if (historyId.isEmpty) {
      throw ArgumentError.value(id, 'id', 'Must not be empty.');
    }
    return historyId;
  }

  Future<HistoryModel> _loadOne({
    required String path,
    CancelToken? cancelToken,
  }) async {
    final historyPath = path.trim();
    if (historyPath.isEmpty) {
      throw ArgumentError.value(path, 'path', 'Must not be empty.');
    }

    try {
      final response = await _dio.get<dynamic>(
        historyPath,
        cancelToken: cancelToken,
      );
      final data = response.data;
      if (data is Map && data['data'] is Map) {
        return HistoryModel.fromJson(
          Map<String, dynamic>.from(data['data'] as Map),
        );
      }
      if (data is Map) {
        return HistoryModel.fromJson(Map<String, dynamic>.from(data));
      }
      throw const ApiException(ApiFailure.unknown);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<List<HistoryModel>> _load({
    required String path,
    String? type,
    CancelToken? cancelToken,
  }) async {
    final normalizedType = type?.trim();
    if (normalizedType != null && normalizedType.isEmpty) {
      throw ArgumentError.value(type, 'type', 'Must not be empty.');
    }

    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: normalizedType == null
            ? null
            : {'type': normalizedType},
        cancelToken: cancelToken,
      );

      final items = _responseItems(response.data);
      return items
          .whereType<Map>()
          .where((item) {
            if (normalizedType == null) {
              return true;
            }
            final itemType = item['type']?.toString().trim().toLowerCase() ?? '';
            if (normalizedType.toLowerCase() == 'ftth_bill') {
              return itemType == 'ftth_bill' || itemType == 'cg_bill';
            }
            return itemType == normalizedType.toLowerCase();
          })
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
