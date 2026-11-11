import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_endpoints/api_endpoints.dart';
import '../../core/network/api_exception.dart';
import '../../core/network/dio_client/dio_client.dart';

class PayBillQuote {
  const PayBillQuote({
    required this.account,
    required this.serviceType,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.productSpeed,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.outstandingAmount,
  });

  final String account;
  final String serviceType;
  final String productId;
  final String productName;
  final num productPrice;
  final String productSpeed;
  final String customerName;
  final String phone;
  final String address;
  final num outstandingAmount;

  factory PayBillQuote.fromJson(Map<String, dynamic> json) {
    return PayBillQuote(
      account: json['account']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      productPrice: _num(json['product_price']),
      productSpeed: json['product_speed']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      outstandingAmount: _num(json['outstanding_amount']),
    );
  }
}

class PayBillReceipt {
  PayBillReceipt({
    required this.transactionNo,
    required this.amount,
    required this.status,
    this.account = '',
    this.serviceType = '',
    this.productName = '',
    this.productId = '',
    this.productSpeed = '',
    String? remark,
    this.createdAt,
  }) : remark = remark ?? '';

  final String transactionNo;
  final String amount;
  final String status;
  final String account;
  final String serviceType;
  final String productName;
  final String productId;
  final String productSpeed;
  final String remark;
  final DateTime? createdAt;

  factory PayBillReceipt.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final package = data['package'] is Map
        ? Map<String, dynamic>.from(data['package'] as Map)
        : const <String, dynamic>{};
    return PayBillReceipt(
      transactionNo: data['transaction_no']?.toString() ?? '',
      amount: data['amount']?.toString() ?? '',
      status: (data['billing_status'] ?? data['status'])?.toString() ?? '',
      account: data['account']?.toString() ?? '',
      serviceType: data['service_type']?.toString() ?? '',
      productName: package['product_name']?.toString() ?? '',
      productId: package['product_id']?.toString() ?? '',
      productSpeed: package['product_speed']?.toString() ?? '',
      remark: _text(data['remark']),
      createdAt: _parseTime(data['confirmed_at'] ?? data['created_at']),
    );
  }

  String get productLabel {
    final name = productName.trim();
    final id = productId.trim();
    if (name.isEmpty) return id;
    if (id.isEmpty) return name;
    return '$name · $id';
  }

  int get amountPoints {
    final parsed = num.tryParse(amount.trim());
    if (parsed == null) return 0;
    return parsed.round();
  }
}

class PayBillRepository {
  PayBillRepository(this._dio);

  final Dio _dio;

  Future<PayBillQuote> check({
    required String accountNumber,
    required String serviceType,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.internetBillCheck,
        data: {
          'account_number': accountNumber,
          'service_type': serviceType,
        },
      );
      final body = response.data ?? {};
      final data = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : <String, dynamic>{};
      return PayBillQuote.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<PayBillReceipt> pay({
    required String accountNumber,
    required String serviceType,
    required String idempotencyKey,
    required String password,
    String remark = '',
  }) async {
    try {
      final note = remark.trim();
      final response = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.internetBillPay,
        data: {
          'broadband_account_number': accountNumber,
          'service_type': serviceType,
          'idempotency_key': idempotencyKey,
          'password': password,
          if (note.isNotEmpty) 'remark': note,
        },
      );
      return PayBillReceipt.fromJson(response.data ?? {});
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}

String _text(Object? value) {
  if (value == null) return '';
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') return '';
  return text;
}

num _num(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _parseTime(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst(' ', 'T'));
}

final payBillRepositoryProvider = Provider<PayBillRepository>((ref) {
  return PayBillRepository(ref.watch(dioProvider));
});
