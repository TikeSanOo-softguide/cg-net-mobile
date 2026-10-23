import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

enum FailureType {
  noInternet('no_internet', 'type_no_internet', LucideIcons.wifi_off),
  slow('slow', 'type_slow_speed', LucideIcons.gauge),
  unstable('unstable', 'type_unstable_connection', LucideIcons.activity),
  password('password', 'type_password_issue', LucideIcons.lock),
  equipment('equipment', 'type_equipment_failure', LucideIcons.settings),
  other('other', 'type_other', LucideIcons.ellipsis);

  const FailureType(this.apiKey, this.localizationKey, this.icon);

  final String apiKey;
  final String localizationKey;
  final IconData icon;

  static FailureType fromKey(String key) {
    return FailureType.values.firstWhere(
      (e) => e.apiKey == key.toLowerCase().trim(),
      orElse: () => FailureType.other,
    );
  }
}

class FailurePhotoModel {
  const FailurePhotoModel({
    required this.id,
    required this.failureReportId,
    required this.imageUrl,
    this.label,
    this.createdAt,
  });

  final String id;
  final String failureReportId;
  final String imageUrl;
  final String? label;
  final DateTime? createdAt;

  factory FailurePhotoModel.fromJson(Map<String, dynamic> json) {
    return FailurePhotoModel(
      id: (json['id'] ?? '').toString(),
      failureReportId: (json['failure_report_id'] ?? '').toString(),
      imageUrl: json['image_url']?.toString() ?? '',
      label: json['label']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
    };
  }
}

class FailureReportModel {
  const FailureReportModel({
    required this.id,
    required this.userId,
    required this.failureType,
    required this.description,
    required this.contactName,
    required this.contactPhone,
    this.broadbandAccountNumber,
    this.status = 'under_review',
    this.photos = const [],
    this.adminId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int userId;
  final String failureType;
  final String description;
  final String contactName;
  final String contactPhone;
  final String? broadbandAccountNumber;
  final String status;
  final List<FailurePhotoModel> photos;
  final int? adminId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FailureReportModel copyWith({String? status}) {
    return FailureReportModel(
      id: id,
      userId: userId,
      broadbandAccountNumber: broadbandAccountNumber,
      failureType: failureType,
      description: description,
      contactName: contactName,
      contactPhone: contactPhone,
      status: status ?? this.status,
      photos: photos,
      adminId: adminId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory FailureReportModel.fromJson(
    Map<String, dynamic> json, {
    bool includePhotos = true,
  }) {
    Map<String, dynamic> rawData = json;
    if (json['data'] is Map) {
      rawData = Map<String, dynamic>.from(json['data'] as Map);
    }

    final rawPhotos = includePhotos
        ? rawData['photos'] ?? rawData['failure_photos']
        : null;
    final photoList = rawPhotos is List
        ? rawPhotos
            .whereType<Map>()
            .map((p) => FailurePhotoModel.fromJson(Map<String, dynamic>.from(p)))
            .toList()
        : <FailurePhotoModel>[];

    return FailureReportModel(
      id: (rawData['id'] ?? '').toString(),
      userId: _toInt(rawData['user_id'] ?? rawData['id']) ?? 0,
      broadbandAccountNumber:
          rawData['broadband_account_number']?.toString(),
      failureType: rawData['failure_type']?.toString() ?? 'other',
      description: rawData['description']?.toString() ?? '',
      contactName: rawData['contact_name']?.toString() ?? '',
      contactPhone: rawData['contact_phone']?.toString() ?? '',
      status: rawData['status']?.toString() ?? 'under_review',
      photos: photoList,
      adminId: _toInt(rawData['admin_id']),
      createdAt: DateTime.tryParse(rawData['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(rawData['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (broadbandAccountNumber != null && broadbandAccountNumber!.isNotEmpty)
        'broadband_account_number': broadbandAccountNumber,
      'failure_type': failureType,
      'description': description,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'status': status,
      if (photos.isNotEmpty)
        'photos': photos.map((p) => p.toJson()).toList(),
    };
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
