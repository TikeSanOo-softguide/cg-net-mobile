class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    this.announcements = true,
    this.system = true,
    this.promotion = true,
    this.general = true,
  });

  final bool announcements;
  final bool system;
  final bool promotion;
  final bool general;

  factory NotificationPreferencesModel.fromJson(
  Map<String, dynamic> json,
  ) {
    return NotificationPreferencesModel(
      announcements: _readBool(
        json,
        const ['announcements_notifications'],
        fallback: true,
      ),
      system: _readBool(
        json,
        const ['system_notifications'],
        fallback: true,
      ),
      promotion: _readBool(
        json,
        const ['promotion_notifications'],
        fallback: true,
      ),
      general: _readBool(
        json,
        const ['general_notifications'],
        fallback: true,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'announcements_notifications': announcements,
        'system_notifications': system,
        'promotion_notifications': promotion,
        'general_notifications': general,
      };

  NotificationPreferencesModel copyWith({
    bool? announcements,
    bool? system,
    bool? promotion,
    bool? general,
  }) {
    return NotificationPreferencesModel(
      announcements: announcements ?? this.announcements,
      system: system ?? this.system,
      promotion: promotion ?? this.promotion,
      general: general ?? this.general,
    );
  }

  static bool _readBool(
    Map<String, dynamic> json,
    List<String> keys, {
    required bool fallback,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num && (value == 0 || value == 1)) return value == 1;
      if (value is String) {
        switch (value.toLowerCase().trim()) {
          case 'true':
          case '1':
            return true;
          case 'false':
          case '0':
            return false;
        }
      }
    }
    return fallback;
  }
}
