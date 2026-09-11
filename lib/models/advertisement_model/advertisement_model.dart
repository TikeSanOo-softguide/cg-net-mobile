/// Launch / interstitial advertisement — shaped for future Laravel API payload.
class Advertisement {
  const Advertisement({
    required this.id,
    required this.image,
    required this.durationSeconds,
    required this.isActive,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.actionUrl,
    this.actionType,
  });

  final String id;

  /// Asset path or remote URL (network images later).
  final String image;
  final String? title;
  final String? description;

  /// Countdown before auto-continue.
  final int durationSeconds;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? actionUrl;

  /// e.g. `none`, `url`, `deeplink` — reserved for API.
  final String? actionType;

  bool get isCurrentlyValid {
    if (!isActive) return false;
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return image.trim().isNotEmpty;
  }

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return Advertisement(
      id: json['id']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      title: json['title']?.toString(),
      description: json['description']?.toString(),
      durationSeconds: (json['duration'] as num?)?.toInt() ??
          (json['duration_seconds'] as num?)?.toInt() ??
          5,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      actionUrl: json['action_url']?.toString(),
      actionType: json['action_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image': image,
        'title': title,
        'description': description,
        'duration': durationSeconds,
        'is_active': isActive,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'action_url': actionUrl,
        'action_type': actionType,
      };
}

/// Full-screen skip-timer promo shown before the advertisement step.
class SkipTimerPromo {
  const SkipTimerPromo({
    required this.image,
    this.durationSeconds = 5,
  });

  final String image;
  final int durationSeconds;
}
