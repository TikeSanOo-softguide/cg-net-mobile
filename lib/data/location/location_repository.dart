import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';
import '../../models/location/location_place.dart';

class LocationRepository {
  LocationRepository(this._dio);

  final Dio _dio;

  Future<List<LocationPlace>> fetchStates() {
    return _fetch(ApiEndpoints.states);
  }

  Future<List<LocationPlace>> fetchRegions(int stateId) {
    return _fetch(ApiEndpoints.stateRegions(stateId));
  }

  Future<List<LocationPlace>> fetchAreas(int regionId) {
    return _fetch(ApiEndpoints.regionAreas(regionId));
  }

  Future<List<LocationPlace>> _fetch(String path) async {
    try {
      final response = await _dio.get<dynamic>(path);
      return _placesFromResponse(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  List<LocationPlace> _placesFromResponse(Object? response) {
    Object? raw = response;
    if (response is Map && response['data'] is List) {
      raw = response['data'];
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) {
          try {
            return LocationPlace.fromJson(Map<String, dynamic>.from(item));
          } catch (_) {
            return null;
          }
        })
        .whereType<LocationPlace>()
        .toList(growable: false);
  }
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.watch(dioProvider));
});
