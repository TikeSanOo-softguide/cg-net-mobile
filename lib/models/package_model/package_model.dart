class PackageModel {
  const PackageModel({
    required this.id,
    required this.name,
    required this.speed,
    required this.price,
    required this.currency,
    required this.billingCycle,
    required this.dataLimit,
    required this.isCurrent,
    required this.features,
    this.imageUrl,
    this.recommended = false,
    this.termMonths,
    this.localizedName,
  });

  final String id;
  final String name;
  final String speed;
  final num price;
  final String currency;
  final String billingCycle;
  final String dataLimit;
  final bool isCurrent;
  final List<String> features;
  final String? imageUrl;
  final bool recommended;
  final int? termMonths;
  final Map<String, String>? localizedName;

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    final speedValue = switch (json['speed']) {
      String value => value,
      Map value => (value['mbps']?.toString() ?? ''),
      _ => '',
    };
    final termMonths = switch (json['term']) {
      Map value => int.tryParse(value['months']?.toString() ?? ''),
      _ => null,
    };
    final localizedName = switch (json['name']) {
      Map value => value.map(
          (key, item) => MapEntry(key.toString(), item?.toString() ?? ''),
        ),
      _ => null,
    };
    final defaultName = localizedName?['en'] ??
        localizedName?['my'] ??
        localizedName?['zh'] ??
        json['name']?.toString() ??
        'Package';

    return PackageModel(
      id: json['id'].toString(),
      name: defaultName,
      speed: speedValue,
      price: json['price'] as num,
      currency: json['currency']?.toString() ?? 'Pts',
      billingCycle: json['billing_cycle']?.toString() ?? 'month',
      dataLimit: json['data_limit']?.toString() ?? '',
      isCurrent: json['is_current'] as bool? ?? false,
      features: (json['features'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      imageUrl: json['image_url']?.toString(),
      recommended: json['recommended'] == true,
      termMonths: termMonths,
      localizedName: localizedName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'speed': speed,
        'price': price,
        'currency': currency,
        'billing_cycle': billingCycle,
        'data_limit': dataLimit,
        'is_current': isCurrent,
        'features': features,
        'image_url': imageUrl,
        'recommended': recommended,
        'term_months': termMonths,
      };

  String get formattedPrice => '$currency ${price.toStringAsFixed(0)}';
}
