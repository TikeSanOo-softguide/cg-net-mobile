class ShowRoom {
  const ShowRoom({
    required this.id,
    required this.code,
    required this.names,
    required this.addresses,
    required this.phoneNumbers,
    required this.socialLinks,
  });

  final int id;
  final String code;
  final Map<String, String> names;
  final Map<String, String> addresses;
  final List<String> phoneNumbers;
  final Map<String, String> socialLinks;

  factory ShowRoom.fromJson(Map<String, dynamic> json) {
    final id = switch (json['id']) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value),
      _ => null,
    };
    if (id == null) {
      throw FormatException('Invalid showroom id: ${json['id']}');
    }

    return ShowRoom(
      id: id,
      code: json['code']?.toString() ?? '',
      names: _localizedValues(json['name']),
      addresses: _localizedValues(json['address']),
      phoneNumbers: json['phone_numbers'] is List
          ? (json['phone_numbers'] as List)
              .whereType<String>()
              .map((phone) => phone.trim())
              .where((phone) => phone.isNotEmpty)
              .toList(growable: false)
          : const [],
      socialLinks: _localizedValues(json['social_links']),
    );
  }

  String nameFor(String locale) => _localizedValue(names, locale);

  String addressFor(String locale) => _localizedValue(addresses, locale);

  static Map<String, String> _localizedValues(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final entry in value.entries)
        if (entry.value != null && entry.value.toString().trim().isNotEmpty)
          entry.key.toString(): entry.value.toString().trim(),
    };
  }

  static String _localizedValue(Map<String, String> values, String locale) {
    final language = locale == 'mm' ? 'my' : locale;
    return values[language] ??
        values['en'] ??
        values['my'] ??
        values['zh'] ??
        '';
  }
}
