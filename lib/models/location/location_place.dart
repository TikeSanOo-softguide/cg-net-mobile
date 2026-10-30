class LocationPlace {
  const LocationPlace({
    required this.id,
    required this.names,
  });

  final int id;
  final Map<String, String> names;

  factory LocationPlace.fromJson(Map<String, dynamic> json) {
    final id = switch (json['id']) {
      final int value => value,
      final num value => value.toInt(),
      final String value => int.tryParse(value),
      _ => null,
    };
    if (id == null) {
      throw FormatException('Invalid location id: ${json['id']}');
    }

    final rawName = json['name'];
    final names = <String, String>{};
    if (rawName is Map) {
      for (final entry in rawName.entries) {
        final value = entry.value?.toString().trim() ?? '';
        if (value.isNotEmpty) names[entry.key.toString()] = value;
      }
    } else if (rawName is String && rawName.trim().isNotEmpty) {
      names['en'] = rawName.trim();
    }

    return LocationPlace(id: id, names: names);
  }

  String labelFor(String locale) {
    return names[locale] ??
        names['en'] ??
        names['my'] ??
        names['zh'] ??
        '';
  }
}
