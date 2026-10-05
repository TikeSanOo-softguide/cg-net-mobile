import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../models/user_model/user_model.dart';

class InboxRepository {
  InboxRepository(this._dio);

  final Dio _dio;

  Future<List<InboxMessageModel>> fetch({CancelToken? cancelToken}) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.inbox,
        cancelToken: cancelToken,
      );
      final data = response.data;
      final list =
          data is Map && data['data'] is List ? data['data'] as List : const [];
      return list
          .map(
            (item) => InboxMessageModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

final inboxRepositoryProvider = Provider<InboxRepository>((ref) {
  return InboxRepository(ref.watch(dioProvider));
});
