import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/package_model/package_model.dart';

class PackageListRepository {
  PackageListRepository(this._dio);

  final Dio _dio;

  /// Fallback source kept for local/offline scaffolding.
  Future<List<PackageModel>> fetchPackagesMock() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final raw = await rootBundle.loadString('assets/mock/packages.json');
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PackageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Web-app package catalog from backend.
  Future<List<PackageModel>> fetchPackages() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.availablePlans);
    final data = response.data;
    final list = (data is Map && data['data'] is List)
        ? data['data'] as List
        : (data is List ? data : const []);
    return list
        .map((e) => PackageModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

final packageListRepositoryProvider = Provider<PackageListRepository>((ref) {
  return PackageListRepository(ref.watch(dioProvider));
});
