enum InboxCategory { announcement, system, promotion }

class InboxMessageModel {
  const InboxMessageModel({
    required this.id,
    required this.titleKey,
    required this.bodyKey,
    required this.createdAt,
    required this.category,
    this.detailKey,
    this.titles,
    this.bodies,
    this.isRead = false,
    this.isFailure = false,
  });

  final String id;
  final String titleKey;
  final String bodyKey;
  final String? detailKey;
  final Map<String, String>? titles;
  final Map<String, String>? bodies;
  final DateTime createdAt;
  final InboxCategory category;
  final bool isRead;
  final bool isFailure;

  factory InboxMessageModel.fromJson(Map<String, dynamic> json) {
    final titles = _stringMap(json['title']);
    final bodies = _stringMap(json['body']);
    final category = switch (json['category']) {
      'announcement' => InboxCategory.announcement,
      'promotion' => InboxCategory.promotion,
      _ => InboxCategory.system,
    };

    return InboxMessageModel(
      id: json['id'].toString(),
      titleKey: titles['en'] ?? '',
      bodyKey: bodies['en'] ?? '',
      titles: titles,
      bodies: bodies,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      category: category,
      isRead: json['is_read'] == true,
      isFailure: json['is_failure'] == true,
    );
  }

  String titleFor(String locale) => _pick(titles, titleKey, locale);

  String bodyFor(String locale) => _pick(bodies, detailKey ?? bodyKey, locale);

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
    );
  }

  static String _pick(
      Map<String, String>? values, String fallback, String locale) {
    if (values == null || values.isEmpty) return fallback;
    final picked = values[locale] ?? values['en'] ?? '';
    return picked.isEmpty ? fallback : picked;
  }
}

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.accountNumber,
    this.status = 'active',
    this.username,
  });

  final String id;
  final String fullName;
  final String phone;
  final String accountNumber;
  final String status;
  final String? username;

  String get displayPhone => formatLocalPhone(phone);

  static String formatLocalPhone(String rawPhone) {
    var value = rawPhone.trim().replaceAll(RegExp(r'[\s().-]+'), '');
    if (value.startsWith('+')) {
      value = value.substring(1);
    }
    if (value.startsWith('959')) {
      return '09${value.substring(3)}';
    }
    if (value.startsWith('950')) {
      return '0${value.substring(3)}';
    }
    if (value.startsWith('95')) {
      return '0${value.substring(2)}';
    }
    if (!value.startsWith('0') && value.startsWith('9') && value.length >= 8) {
      return '0$value';
    }
    return rawPhone;
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> rawData = json;
    if (json['data'] is Map) {
      rawData = Map<String, dynamic>.from(json['data'] as Map);
      if (rawData['user'] is Map) {
        rawData = Map<String, dynamic>.from(rawData['user'] as Map);
      }
    } else if (json['user'] is Map) {
      rawData = Map<String, dynamic>.from(json['user'] as Map);
    }

    final id = (rawData['id'] ?? rawData['user_id'] ?? '').toString();
    final fullName = rawData['name']?.toString() ??
        rawData['full_name']?.toString() ??
        rawData['fullName']?.toString() ??
        '';
    final rawPhone = rawData['phone']?.toString() ??
        rawData['phone_number']?.toString() ??
        rawData['mobile']?.toString() ??
        '';
    final phone = formatLocalPhone(rawPhone);
    final accountNumber = rawData['broadband_account_number']?.toString() ??
        rawData['account_number']?.toString() ??
        rawData['account_no']?.toString() ??
        rawData['accountNumber']?.toString() ??
        rawData['customer_id']?.toString() ??
        rawData['user_code']?.toString() ??
        '';
    final status = rawData['status']?.toString() ?? 'active';
    final username = rawData['username']?.toString();

    return UserProfileModel(
      id: id,
      fullName: fullName,
      phone: phone,
      accountNumber: accountNumber,
      status: status,
      username: username,
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? accountNumber,
    String? status,
    String? username,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone != null ? formatLocalPhone(phone) : this.phone,
      accountNumber: accountNumber ?? this.accountNumber,
      status: status ?? this.status,
      username: username ?? this.username,
    );
  }
}
