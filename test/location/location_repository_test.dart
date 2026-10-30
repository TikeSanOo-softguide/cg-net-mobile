import 'dart:typed_data';

import 'package:cg_net_mobile/core/network/api_endpoints/api_endpoints.dart';
import 'package:cg_net_mobile/data/location/location_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loads states, regions, and areas from Laravel location APIs', () async {
    final requests = <RequestOptions>[];
    final repository = LocationRepository(
      _dio((options) {
        requests.add(options);
        if (options.path == ApiEndpoints.states) {
          return _jsonResponse(
            '{"data":[{"id":1,"name":{"en":"Shan","my":"ရှမ်း","zh":"掸邦"}}]}',
          );
        }
        if (options.path == ApiEndpoints.stateRegions(1)) {
          return _jsonResponse(
            '{"data":[{"id":8,"name":{"en":"Taunggyi","my":"တောင်ကြီး","zh":"东枝"}}]}',
          );
        }
        return _jsonResponse(
          '{"data":[{"id":22,"name":{"en":"Aungban","my":"အောင်ပန်း","zh":"翁班"}}]}',
        );
      }),
    );

    final states = await repository.fetchStates();
    final regions = await repository.fetchRegions(1);
    final areas = await repository.fetchAreas(8);

    expect(states.single.id, 1);
    expect(states.single.labelFor('my'), 'ရှမ်း');
    expect(regions.single.labelFor('en'), 'Taunggyi');
    expect(areas.single.id, 22);
    expect(
      requests.map((item) => item.path),
      [
        ApiEndpoints.states,
        ApiEndpoints.stateRegions(1),
        ApiEndpoints.regionAreas(8),
      ],
    );
  });
}

Dio _dio(ResponseBody Function(RequestOptions options) respond) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'));
  dio.httpClientAdapter = _ResponseAdapter(respond);
  return dio;
}

ResponseBody _jsonResponse(String body) {
  return ResponseBody.fromString(
    body,
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

class _ResponseAdapter implements HttpClientAdapter {
  _ResponseAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}
