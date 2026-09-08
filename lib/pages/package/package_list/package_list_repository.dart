import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/package_model/package_model.dart';

class PackageListRepository {
  PackageListRepository(this._dio);

  // Kept for the real API method below (uncomment when backend is ready).
  // ignore: unused_field
  final Dio _dio;

  /// Loads packages from local mock JSON for scaffold / offline demo.
  Future<List<PackageModel>> fetchPackagesMock() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final raw = await rootBundle.loadString('assets/mock/packages.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PackageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Real API — uncomment and switch the controller to call this later.
  /// GET /v1/customer/plans/available  (see ApiEndpoints.availablePlans)
  // Future<List<PackageModel>> fetchPackages() async {
  //   final response = await _dio.get(ApiEndpoints.availablePlans);
  //   final data = response.data;
  //   final list = (data is Map && data['data'] is List)
  //       ? data['data'] as List
  //       : data as List;
  //   return list
  //       .map((e) => PackageModel.fromJson(Map<String, dynamic>.from(e as Map)))
  //       .toList();
  // }
}

final packageListRepositoryProvider = Provider<PackageListRepository>((ref) {
  return PackageListRepository(ref.watch(dioProvider));
});
