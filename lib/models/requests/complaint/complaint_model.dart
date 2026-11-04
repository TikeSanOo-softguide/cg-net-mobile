import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../core/utils/image_url_helper.dart';

enum ComplaintType {
  noInternet('no_internet', 'type_no_internet', LucideIcons.wifi_off),
  slow('slow', 'type_slow_speed', LucideIcons.gauge),
  unstable('unstable', 'type_unstable_connection', LucideIcons.activity),
  password('password', 'type_password_issue', LucideIcons.lock),
  equipment('equipment', 'type_equipment_failure', LucideIcons.settings),
  other('other', 'type_other', LucideIcons.ellipsis);

  const ComplaintType(this.apiKey, this.localizationKey, this.icon);

  final String apiKey;
  final String localizationKey;
  final IconData icon;

  static ComplaintType fromKey(String key) {
    return ComplaintType.values.firstWhere(
      (e) => e.apiKey == key.toLowerCase().trim(),
      orElse: () => ComplaintType.other,
    );
  }
}

class ComplaintPhotoModel {
  const ComplaintPhotoModel({
    required this.id,
    required this.complaintId,
    required this.imageUrl,
    this.label,
    this.createdAt,
  });

  final String id;
  final String complaintId;
  final String imageUrl;
  final String? label;
  final DateTime? createdAt;

  factory ComplaintPhotoModel.fromJson(Map<String, dynamic> json) {
    return ComplaintPhotoModel(
      id: (json['id'] ?? '').toString(),
      complaintId: (json['failure_report_id'] ?? '').toString(),
      imageUrl: ImageUrlHelper.resolve({'image_url': json['image_url']}) ?? '',
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

class ComplaintModel {
  const ComplaintModel({
    required this.id,
    required this.userId,
    required this.complaintType,
    required this.description,
    required this.contactName,
    required this.contactPhone,
    this.broadbandAccountNumber,
    this.ticketNumber,
    this.status = 'under_review',
    this.photos = const [],
    this.adminId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int userId;
  final String complaintType;
  final String description;
  final String contactName;
  final String contactPhone;
  final String? broadbandAccountNumber;
  final String? ticketNumber;
  final String status;
  final List<ComplaintPhotoModel> photos;
  final int? adminId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ComplaintModel copyWith({String? status}) {
    return ComplaintModel(
      id: id,
      userId: userId,
      broadbandAccountNumber: broadbandAccountNumber,
      complaintType: complaintType,
      description: description,
      contactName: contactName,
      contactPhone: contactPhone,
      ticketNumber: ticketNumber,
      status: status ?? this.status,
      photos: photos,
      adminId: adminId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory ComplaintModel.fromJson(
    Map<String, dynamic> json, {
    bool includePhotos = true,
  }) {
    Map<String, dynamic> rawData = json;
    if (json['data'] is Map) {
      rawData = Map<String, dynamic>.from(json['data'] as Map);
    }

    final rawPhotos =
        includePhotos ? rawData['photos'] ?? rawData['failure_photos'] : null;
    final photoList = rawPhotos is List
        ? rawPhotos
            .whereType<Map>()
            .map((p) =>
                ComplaintPhotoModel.fromJson(Map<String, dynamic>.from(p)))
            .toList()
        : <ComplaintPhotoModel>[];

    return ComplaintModel(
      id: (rawData['id'] ?? '').toString(),
      userId: _toInt(rawData['user_id'] ?? rawData['id']) ?? 0,
      broadbandAccountNumber: rawData['broadband_account_number']?.toString(),
      ticketNumber: rawData['ticket_number']?.toString(),
      complaintType: rawData['failure_type']?.toString() ?? 'other',
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
      'failure_type': complaintType,
      'description': description,
      'contact_name': contactName,
      'contact_phone': contactPhone,
      'status': status,
      if (photos.isNotEmpty) 'photos': photos.map((p) => p.toJson()).toList(),
    };
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
