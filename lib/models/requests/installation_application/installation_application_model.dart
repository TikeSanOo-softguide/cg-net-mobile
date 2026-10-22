class InstallationApplicationModel {
  const InstallationApplicationModel({
    required this.id,
    required this.userId,
    required this.packageId,
    required this.areaId,
    required this.idType,
    required this.idName,
    required this.idNumber,
    required this.address,
    required this.phone,
    required this.photos,
    required this.note,
    this.status = 'under_review',
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final int userId;
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
}

class InstallationApplicationOption {
  const InstallationApplicationOption({
    required this.id,
    required this.names,
  });

  final int id;
  final Map<String, String> names;

  factory InstallationApplicationOption.fromJson(
    Map<String, dynamic> json,
  ) {
    final id = _toInt(json['id']);

    if (id == null) {
      throw FormatException(
        'Invalid installation application option: invalid id. '
        'Received: ${json['id']}',
      );
    }

    final rawName = json['name'] ?? json['title'];

    final Map<String, String> names;

    if (rawName is Map) {
      names = rawName.map(
        (key, value) => MapEntry(
          key.toString(),
          value?.toString() ?? '',
        ),
      );
    } else if (json['name_en'] != null ||
        json['name_zh'] != null ||
        json['name_my'] != null) {
      names = {
        'en': json['name_en']?.toString() ?? '',
        'zh': json['name_zh']?.toString() ?? '',
        'my': json['name_my']?.toString() ?? '',
      };
    } else if (json['network'] != null) {
      final network = json['network'];

      if (network is Map) {
        names = {
          'en': network['name_en']?.toString() ??
              network['name']?.toString() ??
              '',
          'zh': network['name_zh']?.toString() ?? '',
          'my': network['name_my']?.toString() ?? '',
        };
      } else {
        names = {'en': network.toString()};
      }
    } else {
      names = {'en': rawName?.toString() ?? ''};
    }

    if (names.values.every((name) => name.trim().isEmpty)) {
      throw FormatException(
        'Invalid installation application option: missing name. '
        'Received keys: ${json.keys.toList()}',
      );
    }

    return InstallationApplicationOption(
      id: id,
      names: names,
    );
  }

  String localizedName(String locale) {
    final localized = names[locale]?.trim();
    if (localized?.isNotEmpty == true) return localized!;
    final english = names['en']?.trim();
    if (english?.isNotEmpty == true) return english!;
    return names.values.first;
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
