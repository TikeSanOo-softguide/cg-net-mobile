class RelocationRequestModel {
  const RelocationRequestModel({
    required this.id,
    required this.userId,
    this.broadbandAccountNumber,
    required this.currentAddress,
    required this.newAddress,
    required this.phone,
    this.preferredDate,
    this.details,
    this.status = 'under_review',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int userId;
  final String? broadbandAccountNumber;
  final String currentAddress;
  final String newAddress;
  final DateTime? preferredDate;
  final String phone;
  final String? details;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RelocationRequestModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return RelocationRequestModel(
      id: data['id']?.toString() ?? '',
      userId: _toInt(data['user_id']) ?? 0,
      broadbandAccountNumber: data['broadband_account_number']?.toString(),
      currentAddress: data['current_address']?.toString() ?? '',
      newAddress: data['new_address']?.toString() ?? '',
      preferredDate:
          DateTime.tryParse(data['preferred_date']?.toString() ?? ''),
      phone: data['phone']?.toString() ?? '',
      details: data['details']?.toString(),
      status: data['status']?.toString() ?? 'under_review',
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'broadband_account_number': broadbandAccountNumber,
        'current_address': currentAddress,
        'new_address': newAddress,
        'preferred_date': preferredDate?.toIso8601String().split('T').first,
        'phone': phone,
        'details': details,
        'status': status,
      };

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
