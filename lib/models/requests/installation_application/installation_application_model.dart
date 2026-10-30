class InstallationApplicationModel {
  const InstallationApplicationModel({
    required this.id,
    required this.userId,
    this.productId,
    this.productName,
    required this.packageId,
    required this.areaId,
    required this.idType,
    required this.idName,
    required this.idNumber,
    required this.address,
    required this.phone,
    required this.photos,
    required this.note,
    this.serviceType,
    this.status = 'under_review',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int userId;
  final String? serviceType;
  final String? productId;
  final String? productName;
  final int? packageId;
  final int? areaId;
  final String idType;
  final String idName;
  final String? idNumber;
  final String? address;
  final String phone;
  final List<Map<String, dynamic>> photos;
  final String? note;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory InstallationApplicationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    final rawPhotos = data['photos'];

    return InstallationApplicationModel(
      id: data['id']?.toString() ?? '',
      userId: _toInt(data['user_id']) ?? 0,
      serviceType: _normalizeServiceType(data['service_type']),
      productId: data['product_id']?.toString() ??
          data['productID']?.toString(),
      productName: data['product_name']?.toString() ??
          data['productName']?.toString(),
      packageId: _toInt(data['package_id']),
      areaId: _toInt(data['area_id']),
      idType: data['id_type']?.toString() ?? '',
      idName: data['id_name']?.toString() ?? '',
      idNumber: data['id_number']?.toString(),
      address: data['address']?.toString(),
      phone: data['phone']?.toString() ?? '',
      photos: rawPhotos is List
          ? rawPhotos
              .whereType<Map>()
              .map((photo) => Map<String, dynamic>.from(photo))
              .toList()
          : const [],
      note: data['note']?.toString(),
      status: data['status']?.toString() ?? 'under_review',
      createdAt: DateTime.tryParse(
        data['created_at']?.toString() ?? '',
      ),
      updatedAt: DateTime.tryParse(
        data['updated_at']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'service_type': serviceType,
        'product_id': productId,
        'product_name': productName,
        'package_id': packageId,
        'area_id': areaId,
        'id_type': idType,
        'id_name': idName,
        'id_number': idNumber,
        'address': address,
        'phone': phone,
        'photos': photos,
        'note': note,
        'status': status,
      };

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double _toDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class InstallationApplicationOption {
  const InstallationApplicationOption({
    required this.productId,
    required this.productName,
    this.productSpeed,
    this.productLine = '',
    this.productPrice = 0,
    this.monthCycle = 1,
    this.monthCycleUnit = '',
    this.installationFee = 0,
  });

  final String productId;
  final String productName;
  final String? productSpeed;
  final String productLine;
  final double productPrice;
  final int monthCycle;
  final String monthCycleUnit;
  final double installationFee;

  factory InstallationApplicationOption.fromJson(
    Map<String, dynamic> json,
  ) {
    final productId = json['productID']?.toString() ??
        json['product_id']?.toString() ??
        json['id']?.toString();
    final productName = json['productName']?.toString() ??
        json['product_name']?.toString() ??
        json['name']?.toString();
    final productSpeed = json['productSpeed']?.toString() ??
        json['product_speed']?.toString();

    if (productId == null || productId.trim().isEmpty) {
      throw FormatException(
        'Invalid installation product: missing productID. '
        'Received keys: ${json.keys.toList()}',
      );
    }
    if (productName == null || productName.trim().isEmpty) {
      throw FormatException(
        'Invalid installation product: missing productName. '
        'Received keys: ${json.keys.toList()}',
      );
    }

    final trimmedSpeed = productSpeed?.trim();

    return InstallationApplicationOption(
      productId: productId,
      productName: productName,
      productSpeed: trimmedSpeed == null || trimmedSpeed.isEmpty
          ? null
          : trimmedSpeed,
      productLine: (json['productLine'] ?? json['product_line'] ?? '')
          .toString()
          .trim(),
      productPrice: InstallationApplicationModel._toDouble(
        json['productPrice'] ?? json['product_price'],
      ),
      monthCycle:
          InstallationApplicationModel._toInt(json['monthCycle'] ?? json['month_cycle']) ??
              1,
      monthCycleUnit:
          (json['monthCycleUnit'] ?? json['month_cycle_unit'] ?? '')
              .toString(),
      installationFee: InstallationApplicationModel._toDouble(
        json['installationFee'] ?? json['installation_fee'],
      ),
    );
  }

  double get totalInitialPayment => productPrice + installationFee;
}

String? _normalizeServiceType(Object? value) {
  final haystack = value?.toString().toUpperCase() ?? '';
  if (haystack.contains('FTTH')) return 'FTTH';
  if (RegExp(r'(^|[^A-Z0-9])CG([^A-Z0-9]|$)').hasMatch(haystack) ||
      haystack.startsWith('CG')) {
    return 'CG';
  }
  return null;
}
