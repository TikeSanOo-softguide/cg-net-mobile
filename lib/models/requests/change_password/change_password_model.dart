class ChangePasswordRequestModel {
  const ChangePasswordRequestModel({
    required this.id,
    required this.userId,
    required this.contactName,
    required this.contactPhone,
    required this.newPassword,
    this.broadbandAccountNumber,
    this.newWifiName,
    this.status = 'under_review',
    this.adminId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int userId;
  final String? broadbandAccountNumber;
  final String contactName;
  final String contactPhone;
  final String? newWifiName;
  final String newPassword;
  final String status;
  final int? adminId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ChangePasswordRequestModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> rawData = json;
    if (json['data'] is Map) {
      rawData = Map<String, dynamic>.from(json['data'] as Map);
    }

    return ChangePasswordRequestModel(
      id: (rawData['id'] ?? '').toString(),
      userId: _toInt(rawData['user_id']) ?? 1,
      broadbandAccountNumber:
          rawData['broadband_account_number']?.toString(),
      contactName: rawData['contact_name']?.toString() ?? '',
      contactPhone: rawData['contact_phone']?.toString() ?? '',
      newWifiName: rawData['new_wifi_name']?.toString(),
      newPassword: rawData['new_password']?.toString() ?? '',
      status: rawData['status']?.toString() ?? 'under_review',
      adminId: _toInt(rawData['admin_id']),
      createdAt:
          DateTime.tryParse(rawData['created_at']?.toString() ?? ''),
      updatedAt:
          DateTime.tryParse(rawData['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId > 0 ? userId : 1,
      'broadband_account_number': broadbandAccountNumber ?? '',
      'contact_name': contactName,
      'contact_phone': contactPhone,
      if (newWifiName != null && newWifiName!.isNotEmpty)
        'new_wifi_name': newWifiName,
      'new_password': newPassword,
      'status': status,
    };
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
