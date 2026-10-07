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
    this.email,
    this.username,
    this.walletBalance,
  });

  final String id;
  final String fullName;
  final String phone;
  final String accountNumber;
  final String? email;
  final String? username;
  final num? walletBalance;

  factory UserProfileModel.fromCustomerProfileJson(Object? json) {
    final envelope = _asMap(json);
    final resource = _asMap(envelope['data']);
    final payload = resource.isEmpty ? envelope : resource;
    final user = _asMap(payload['user']);
    final wallet = _asMap(payload['wallet']);
    final phone = _firstValue(user, ['phone', 'mobile', 'phone_number']);

    return UserProfileModel(
      id: _firstValue(user, ['id']) ?? '',
      fullName: _firstValue(user, ['full_name', 'name']) ?? '',
      phone: phone ?? '',
      accountNumber: _firstValue(
            user,
            ['account_number', 'account_no', 'customer_number'],
          ) ??
          phone ??
          '',
      email: _firstValue(user, ['email']),
      username: _firstValue(user, ['username']),
      walletBalance: _asNum(
        wallet['balance'] ?? wallet['balance_points'] ?? wallet['points'],
      ),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), item),
      );
    }
    return const {};
  }

  static String? _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  static num? _asNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
