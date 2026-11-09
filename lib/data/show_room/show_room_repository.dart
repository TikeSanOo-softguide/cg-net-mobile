import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../models/show_room_model/show_room_model.dart';

class ShowRoomRepository {
  ShowRoomRepository(this._dio);

  final Dio _dio;

  Future<List<ShowRoom>> fetchShowRooms() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.showrooms);
      final rawItems = _itemsFromResponse(response.data);
      return rawItems
          .whereType<Map>()
          .map((item) => ShowRoom.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<dynamic> _itemsFromResponse(Object? response) {
    Object? rawItems = response;
    if (response is Map) {
      rawItems = response['data'];
      if (rawItems is Map) {
        rawItems = rawItems['data'];
      }
    }
    return rawItems is List ? rawItems : const [];
  }
}

final showRoomRepositoryProvider = Provider<ShowRoomRepository>((ref) {
  return ShowRoomRepository(ref.watch(dioProvider));
});

final showRoomsProvider = FutureProvider.autoDispose<List<ShowRoom>>((ref) {
  return ref.watch(showRoomRepositoryProvider).fetchShowRooms();
});
