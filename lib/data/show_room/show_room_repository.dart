import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../core/network/offline_navigation.dart';
import '../../core/storage/list_snapshot_store.dart';
import '../../models/show_room_model/show_room_model.dart';

class ShowRoomRepository {
  ShowRoomRepository(this._dio, {ListSnapshotStore? snapshots})
      : _snapshots = snapshots;

  final Dio _dio;
  final ListSnapshotStore? _snapshots;

  Future<List<ShowRoom>> fetchShowRooms() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.showrooms);
      final rawItems = _itemsFromResponse(response.data);
      final maps = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
      await _snapshots?.write(
        ListSnapshotStore.showroom,
        maps,
        shared: true,
      );
      return maps
          .map(ShowRoom.fromJson)
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

  List<ShowRoom>? readCachedShowRooms() {
    return decodeSnapshot(
      _snapshots,
      ListSnapshotStore.showroom,
      ShowRoom.fromJson,
      shared: true,
    );
  }
}

final showRoomRepositoryProvider = Provider<ShowRoomRepository>((ref) {
  return ShowRoomRepository(
    ref.watch(dioProvider),
    snapshots: ref.watch(listSnapshotStoreProvider),
  );
});

final showRoomsOfflineProvider = StateProvider<bool>((ref) => false);

final showRoomsProvider = FutureProvider.autoDispose<List<ShowRoom>>((ref) async {
  final repository = ref.watch(showRoomRepositoryProvider);
  var active = true;
  ref.onDispose(() => active = false);
  try {
    final rooms = await repository.fetchShowRooms();
    if (active) {
      ref.read(showRoomsOfflineProvider.notifier).state = false;
    }
    return rooms;
  } on ApiException catch (error) {
    if (!isOfflineError(error)) rethrow;
    final cached = repository.readCachedShowRooms();
    if (cached == null) rethrow;
    if (active) {
      ref.read(showRoomsOfflineProvider.notifier).state = true;
    }
    return cached;
  }
});
