/// Image displayed in the home advertisement modal.
class Advertisement {
  const Advertisement({
    required this.image,
  });

  final String image;

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      image: json['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'image': image};
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

class BannerModel {
  const BannerModel({
    required this.image,
  });

  final String image;
}
