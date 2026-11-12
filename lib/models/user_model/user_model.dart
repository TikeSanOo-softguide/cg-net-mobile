import '../../core/utils/image_url_helper.dart';

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
    this.imageUrl,
    this.isRead = false,
    this.isFailure = false,
  });

  final String id;
  final String titleKey;
  final String bodyKey;
  final String? detailKey;
  final Map<String, String>? titles;
  final Map<String, String>? bodies;
  final String? imageUrl;
  final DateTime createdAt;
  final InboxCategory category;
  final bool isRead;
  final bool isFailure;

  InboxMessageModel copyWith({bool? isRead}) {
    return InboxMessageModel(
      id: id,
      titleKey: titleKey,
      bodyKey: bodyKey,
      createdAt: createdAt,
      category: category,
      detailKey: detailKey,
      titles: titles,
      bodies: bodies,
      imageUrl: imageUrl,
      isRead: isRead ?? this.isRead,
      isFailure: isFailure,
    );
  }

  factory InboxMessageModel.fromJson(Map<String, dynamic> json) {
    final titleValue = json['title'];
    final bodyValue = json['body'];
    final titles = _stringMap(titleValue);
    final bodies = _stringMap(bodyValue);
    final titleText = titleValue is String ? titleValue : '';
    final bodyText = bodyValue is String ? bodyValue : '';
    final category = switch (json['category']) {
      'announcement' => InboxCategory.announcement,
      'promotion' => InboxCategory.promotion,
      _ => InboxCategory.system,
    };

    return InboxMessageModel(
      id: json['id'].toString(),
      titleKey: titles['en']?.isNotEmpty == true ? titles['en']! : titleText,
      bodyKey: bodies['en']?.isNotEmpty == true ? bodies['en']! : bodyText,
      titles: titles.isEmpty
          ? (titleText.isEmpty ? null : {'en': titleText})
          : titles,
      bodies: bodies.isEmpty
          ? (bodyText.isEmpty ? null : {'en': bodyText})
          : bodies,
      imageUrl: ImageUrlHelper.resolve(json),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      category: category,
      isRead: json['is_read'] == true,
      isFailure: json['is_failure'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': titles ?? titleKey,
      'body': bodies ?? (detailKey ?? bodyKey),
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'category': switch (category) {
        InboxCategory.announcement => 'announcement',
        InboxCategory.promotion => 'promotion',
        InboxCategory.system => 'system',
      },
      'is_read': isRead,
      'is_failure': isFailure,
    };
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

class UserPackageSnapshot {
  const UserPackageSnapshot({
    this.packageId,
    this.price,
    this.networkName = const {},
    this.speedMbps,
    this.termMonths,
    this.termCycle,
    this.termCycleUnit,
  });

  final int? packageId;
  final num? price;
  final Map<String, String> networkName;
  final String? speedMbps;
  final int? termMonths;
  final int? termCycle;
  final String? termCycleUnit;

  factory UserPackageSnapshot.fromJson(Map<String, dynamic> json) {
    final details = json['details'] is Map
        ? Map<String, dynamic>.from(json['details'] as Map)
        : json;
    final names = details['network_name'] is Map
        ? Map<String, dynamic>.from(details['network_name'] as Map)
        : const <String, dynamic>{};
    final speed = details['speed'] is Map
        ? Map<String, dynamic>.from(details['speed'] as Map)
        : const <String, dynamic>{};
    final term = details['term'] is Map
        ? Map<String, dynamic>.from(details['term'] as Map)
        : const <String, dynamic>{};
    final cycleUnit =
        (term['cycle_unit'] ??
                details['month_cycle_unit'] ??
                details['monthCycleUnit'] ??
                '')
            .toString();
    final cycle = term['cycle'] ??
        details['month_cycle'] ??
        details['monthCycle'] ??
        term['months'];
    final monthCycle = term['months'] ??
        details['month_cycle'] ??
        details['monthCycle'] ??
        (cycleUnit.contains('月') || cycleUnit.toLowerCase().contains('month')
            ? term['cycle']
            : null);

    return UserPackageSnapshot(
      packageId: int.tryParse('${json['package_id'] ?? ''}'),
      price: details['price'] is num
          ? details['price'] as num
          : num.tryParse('${details['price'] ?? ''}'),
      networkName: {
        for (final entry in names.entries)
          if (entry.value != null && '${entry.value}'.trim().isNotEmpty)
            entry.key: '${entry.value}',
      },
      speedMbps: speed['mbps']?.toString(),
      termMonths: int.tryParse('$monthCycle'),
      termCycle: int.tryParse('$cycle'),
      termCycleUnit: cycleUnit.isEmpty ? null : cycleUnit,
    );
  }

  String networkLabel(String locale) {
    return networkName[locale] ??
        networkName['en'] ??
        networkName['my'] ??
        networkName['zh'] ??
        '';
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
    this.packages = const [],
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
  final List<UserPackageSnapshot> packages;

  UserPackageSnapshot? get currentPackage =>
      packages.isEmpty ? null : packages.first;

  int? get currentPackageTermMonths {
    final snapshot = currentPackage;
    final parsedCycle = snapshot?.termMonths;
    if (parsedCycle != null) return parsedCycle;
    final cycleUnit = snapshot?.termCycleUnit?.toLowerCase() ?? '';
    if (cycleUnit.contains('天') || cycleUnit.contains('day')) return null;

    final name = productName.toLowerCase();
    final numericMonths = RegExp(r'(\d+)\s*(?:个月|月|months?|mos?|mo)')
        .firstMatch(name);
    if (numericMonths != null) {
      return int.tryParse(numericMonths.group(1)!);
    }
    if (name.contains('月') || name.contains('monthly')) return 1;
    return null;
  }

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
    final wallet = _readMap(data, json, 'wallet');
    final broadbandAccount = _readMap(data, json, 'broadbandAccount');

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
    final packages = data['packages'] is List
        ? (data['packages'] as List)
            .whereType<Map>()
            .map(
              (item) => UserPackageSnapshot.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList()
        : const <UserPackageSnapshot>[];

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
      packages: packages,
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
    List<UserPackageSnapshot>? packages,
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
      packages: packages ?? this.packages,
    );
  }
}

Map<String, dynamic> _readMap(
  Map<String, dynamic> data,
  Map<String, dynamic> json,
  String key,
) {
  final nested = data[key];
  if (nested is Map) return Map<String, dynamic>.from(nested);
  final root = json[key];
  if (root is Map) return Map<String, dynamic>.from(root);
  return <String, dynamic>{};
}
