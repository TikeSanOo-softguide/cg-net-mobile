import '../../user_model/user_model.dart';
import '../installation_application/installation_application_model.dart';

class ChangePlanRequestModel {
  const ChangePlanRequestModel({
    required this.id,
    required this.userId,
    this.broadbandAccountNumber,
    this.serviceType,
    this.ticketNumber,
    this.currentPackageDetail = const {},
    this.newPackageDetail = const {},
    this.preferredDate,
    required this.contactName,
    required this.contactPhone,
    this.note,
    this.status = 'under_review',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int userId;
  final String? broadbandAccountNumber;
  final String? serviceType;
  final String? ticketNumber;
  final Map<String, dynamic> currentPackageDetail;
  final Map<String, dynamic> newPackageDetail;
  final DateTime? preferredDate;
  final String contactName;
  final String contactPhone;
  final String? note;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChangePlanRequestModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return ChangePlanRequestModel(
      id: data['id']?.toString() ?? '',
      userId: _toInt(data['user_id']) ?? 0,
      broadbandAccountNumber: data['broadband_account_number']?.toString(),
      serviceType: data['service_type']?.toString(),
      ticketNumber: data['ticket_number']?.toString(),
      currentPackageDetail: _map(data['current_package_detail']),
      newPackageDetail: _map(data['new_package_detail']),
      preferredDate: DateTime.tryParse(data['preferred_date']?.toString() ?? ''),
      contactName: data['contact_name']?.toString() ?? '',
      contactPhone: data['contact_phone']?.toString() ?? '',
      note: data['note']?.toString(),
      status: data['status']?.toString() ?? 'under_review',
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'user_id': userId,
      'broadband_account_number': broadbandAccountNumber,
      'service_type': serviceType,
      'current_package_detail': currentPackageDetail,
      'new_package_detail': newPackageDetail,
      'preferred_date': preferredDate?.toIso8601String().split('T').first,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'note': note,
    };
    payload.removeWhere(
      (key, value) =>
          value == null || (value is String && value.trim().isEmpty),
    );
    return payload;
  }

  static Map<String, dynamic> currentDetailFrom(UserProfileModel profile) {
    final snapshot = profile.currentPackage;
    final price = snapshot?.price ?? num.tryParse(profile.productPrice) ?? 0;
    final fallbackNetwork = profile.productLine.trim().isNotEmpty
        ? profile.productLine.trim()
        : profile.productName.trim();
    final networkName = snapshot != null && snapshot.networkName.isNotEmpty
        ? Map<String, String>.from(snapshot.networkName)
        : {
            if (fallbackNetwork.isNotEmpty) 'en': fallbackNetwork,
            if (fallbackNetwork.isNotEmpty) 'my': fallbackNetwork,
            if (fallbackNetwork.isNotEmpty) 'zh': fallbackNetwork,
          };
    final speedRaw = snapshot?.speedMbps ??
        RegExp(r'\d+').firstMatch(profile.productSpeed)?.group(0);
    final speed = num.tryParse(speedRaw ?? '');
    final termMonths = profile.currentPackageTermMonths;
    final termCycle = snapshot?.termCycle ?? termMonths;
    final termCycleUnit = snapshot?.termCycleUnit ??
        (termMonths == null ? null : '月');

    return {
      if (snapshot?.packageId != null) 'package_id': snapshot!.packageId,
      'price': price,
      if (networkName.isNotEmpty) 'network_name': networkName,
      if (speed != null) 'speed': {'mbps': speed},
      if (termMonths != null || termCycle != null || termCycleUnit != null)
        'term': {
          if (termMonths != null) 'months': termMonths,
          if (termCycle != null) 'cycle': termCycle,
          if (termCycleUnit != null) 'cycle_unit': termCycleUnit,
        },
    };
  }

  static Map<String, dynamic> newDetailFrom(
    InstallationApplicationOption product,
  ) {
    final line = product.productLine.trim();
    final speed = int.tryParse(
          RegExp(r'\d+').firstMatch(product.productSpeed ?? '')?.group(0) ?? '',
        ) ??
        0;
    final isDay = product.monthCycleUnit.contains('天');
    return {
      'price': product.productPrice,
      if (line.isNotEmpty)
        'network_name': {'en': line, 'my': line, 'zh': line},
      if (speed > 0) 'speed': {'mbps': speed},
      'term': {
        if (!isDay && product.monthCycle > 0) 'months': product.monthCycle,
        'cycle': product.monthCycle,
        if (product.monthCycleUnit.trim().isNotEmpty)
          'cycle_unit': product.monthCycleUnit,
      },
    };
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
