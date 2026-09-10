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

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id'] as String,
      name: json['name'] as String,
      speed: json['speed'] as String,
      price: json['price'] as num,
      currency: json['currency'] as String,
      billingCycle: json['billing_cycle'] as String,
      dataLimit: json['data_limit'] as String,
      isCurrent: json['is_current'] as bool? ?? false,
      features: (json['features'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
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
      };

  String get formattedPrice => '$currency ${price.toStringAsFixed(0)}';
}
