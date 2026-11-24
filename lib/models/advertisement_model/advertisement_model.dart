/// Pop ups
class Advertisement {
  const Advertisement({
    required this.image,
  });

  final String image;
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
    this.localPath,
  });

  final String image;

  /// Downloaded file on this phone. Empty until the image is saved.
  final String? localPath;
}
