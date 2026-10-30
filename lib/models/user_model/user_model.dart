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
    this.walletBalance = '',
    this.serviceType,
    this.productName = '',
    this.productPrice = '',
    this.startTime = '',
    this.endTime = '',
    this.accountName = '',
    this.accountPhone = '',
    this.accountStatus = '',
    this.address = '',
    this.area = '',
    this.onlineStatus = '',
    this.productLine = '',
    this.productSpeed = '',
  });

  final String id;
  final String fullName;
  final String phone;
  final String accountNumber;
  final String status;
  final String? username;
  final String walletBalance;
  final String? serviceType;
  final String accountName;
  final String accountPhone;
  final String accountStatus;
  final String productName;
  final String startTime;
  final String endTime;
  final String productPrice;
  final String onlineStatus;
  final String address;
  final String area;
  final String productLine;
  final String productSpeed;

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
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final userData = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : data['account'] is Map
            ? Map<String, dynamic>.from(data['account'] as Map)
            : data;
    final accountData = data['account'] is Map
        ? Map<String, dynamic>.from(data['account'] as Map)
        : userData;
    final wallet = data['wallet'] is Map
        ? Map<String, dynamic>.from(data['wallet'] as Map)
        : <String, dynamic>{};
    final broadbandAccount = data['broadbandAccount'] is Map
        ? Map<String, dynamic>.from(data['broadbandAccount'] as Map)
        : <String, dynamic>{};

    final id = (userData['id'] ?? userData['user_id'] ?? '').toString();
    final fullName = userData['name']?.toString() ??
        userData['full_name']?.toString() ??
        userData['fullName']?.toString() ??
        '';
    final rawPhone = userData['phone']?.toString() ??
        userData['phone_number']?.toString() ??
        userData['mobile']?.toString() ??
        '';
    final phone = formatLocalPhone(rawPhone);
    final accountNumber = broadbandAccount['account_number']?.toString() ??
        accountData['account']?.toString() ??
        userData['broadband_account_number']?.toString() ??
        userData['broadband_account']?.toString() ??
        userData['account_number']?.toString() ??
        userData['account_no']?.toString() ??
        userData['account']?.toString() ??
        userData['accountNumber']?.toString() ??
        userData['customer_id']?.toString() ??
        userData['user_code']?.toString() ??
        '';
    final status = userData['status']?.toString() ?? 'active';
    final username = userData['username']?.toString();

    return UserProfileModel(
      id: id,
      fullName: fullName,
      phone: phone,
      accountNumber: accountNumber,
      status: status,
      username: username,
      walletBalance: wallet['balance']?.toString().trim() ?? '',
      serviceType: broadbandAccount['service_type']?.toString(),
      productName: accountData['productName']?.toString() ?? '',
      startTime: accountData['starttime']?.toString() ?? '',
      endTime: accountData['endtime']?.toString() ?? '',
      accountName: accountData['name']?.toString() ?? '',
      accountPhone: accountData['mobile']?.toString() ?? '',
      accountStatus: (accountData['account_status'] ?? accountData['status'])
              ?.toString() ??
          '',
      address: accountData['address']?.toString() ?? '',
      area: accountData['area']?.toString() ?? '',
      onlineStatus: accountData['onlineStatus']?.toString() ?? '',
      productLine: accountData['productLine']?.toString() ?? '',
      productSpeed: accountData['productSpeed']?.toString() ?? '',
      productPrice: accountData['productPrice']?.toString() ?? '',
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? accountNumber,
    String? status,
    String? username,
    String? walletBalance,
    String? serviceType,
    String? productName,
    String? startTime,
    String? endTime,
    String? accountName,
    String? accountPhone,
    String? accountStatus,
    String? address,
    String? area,
    String? onlineStatus,
    String? productLine,
    String? productSpeed,
    String? productPrice,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone != null ? formatLocalPhone(phone) : this.phone,
      accountNumber: accountNumber ?? this.accountNumber,
      status: status ?? this.status,
      username: username ?? this.username,
      walletBalance: walletBalance ?? this.walletBalance,
      serviceType: serviceType ?? this.serviceType,
      productName: productName ?? this.productName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      accountName: accountName ?? this.accountName,
      accountPhone: accountPhone ?? this.accountPhone,
      accountStatus: accountStatus ?? this.accountStatus,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      productLine: productLine ?? this.productLine,
      productSpeed: productSpeed ?? this.productSpeed,
      productPrice: productPrice ?? this.productPrice,
      address: address ?? this.address,
      area: area ?? this.area,
    );
  }
}
