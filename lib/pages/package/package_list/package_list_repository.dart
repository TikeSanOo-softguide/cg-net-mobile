import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_endpoints/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client/dio_client.dart';
import '../../../models/package_model/package_model.dart';

class PackageListRepository {
  PackageListRepository(this._dio);

  final Dio _dio;

  /// CG-NET product list from `GET /web-app/cg-net-products`.
  Future<List<PackageModel>> fetchPackages() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.cgNetProducts);
      final data = response.data;
      final list = data is Map && data['result'] is List
          ? data['result'] as List
          : const [];
      return [
        for (final item in list)
          if (item is Map) _fromCgProduct(Map<String, dynamic>.from(item)),
      ];
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

PackageModel _fromCgProduct(Map<String, dynamic> json) {
  final unit = json['monthCycleUnit']?.toString() ?? '';
  final cycle = int.tryParse('${json['monthCycle'] ?? ''}');
  final productPrice = json['productPrice'];
  final price = productPrice is num
      ? productPrice
      : num.tryParse('$productPrice') ?? 0;

  return PackageModel(
    id: json['productID'].toString(),
    name: json['productName']?.toString() ?? '',
    speed: json['productSpeed']?.toString() ?? '',
    price: price,
    currency: json['productLine']?.toString() ?? '',
    billingCycle: unit,
    dataLimit: '',
    isCurrent: false,
    features: const [],
    termMonths: cycle,
  );
}

final packageListRepositoryProvider = Provider<PackageListRepository>((ref) {
  return PackageListRepository(ref.watch(dioProvider));
});
