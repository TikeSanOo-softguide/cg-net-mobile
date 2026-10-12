import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class CustomerProfile {
  const CustomerProfile({
    required this.phone,
    required this.walletBalance,
  });

  final String phone;
  final String walletBalance;
}

class CustomerProfileRepository {
  CustomerProfileRepository(this._dio);

  final Dio _dio;

  Future<CustomerProfile> fetch() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.profile);
      final root = _asMap(response.data);
      final data = _asMap(root['data']);
      final resource = data.isEmpty ? root : data;
      final user = _asMap(resource['user']);
      final wallet = _asMap(resource['wallet']);
      final phone = user['phone']?.toString().trim();
      final balance = wallet['balance'];
      final walletBalance = balance?.toString().trim();

      if (phone == null || phone.isEmpty) {
        throw const FormatException(
          'Customer profile response is missing the user phone number.',
        );
      }
      if (walletBalance == null || walletBalance.isEmpty) {
        throw const FormatException(
          'Customer profile response is missing the wallet balance.',
        );
      }

      return CustomerProfile(phone: phone, walletBalance: walletBalance);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return const {};
  }
}

final customerProfileRepositoryProvider =
    Provider<CustomerProfileRepository>((ref) {
  return CustomerProfileRepository(ref.watch(dioProvider));
});

final customerProfileProvider =
    FutureProvider.autoDispose<CustomerProfile>((ref) {
  return ref.watch(customerProfileRepositoryProvider).fetch();
});
