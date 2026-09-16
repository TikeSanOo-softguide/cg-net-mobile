import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/advertisement_model/advertisement_model.dart';

/// Local/mock launch creatives. Swap implementation for Laravel API later.
class LaunchPromoRepository {
  static const skipTimerAsset = 'assets/images/launch/skip_timer.png';
  static const networkNoticeAsset = 'assets/images/launch/network_notice.png';
  static const advertisementAsset = 'assets/images/launch/advertisement.png';

  Future<SkipTimerPromo> fetchSkipTimerPromo() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return const SkipTimerPromo(
      image: skipTimerAsset,
      durationSeconds: 5,
    );
  }

  /// Network / outage notice shown before the promotion ad.
  Future<Advertisement?> fetchNetworkNotice() async {
    await Future<void>.delayed(const Duration(milliseconds: 40));

    final notice = Advertisement(
      id: 'local_network_notice',
      image: networkNoticeAsset,
      title: 'Network notice',
      description: 'Service disruption notice',
      durationSeconds: 0,
      isActive: true,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2027, 12, 31, 23, 59, 59),
      actionUrl: null,
      actionType: 'none',
    );

    if (!notice.isCurrentlyValid) return null;
    return notice;
  }

  /// Returns null when no active advertisement should be shown.
  Future<Advertisement?> fetchActiveAdvertisement() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final ad = Advertisement(
      id: 'local_december_promo',
      image: advertisementAsset,
      title: 'December Promotion',
      description: 'Seasonal broadband offer',
      durationSeconds: 5,
      isActive: true,
      startDate: DateTime(2025, 12, 1),
      endDate: DateTime(2026, 12, 31, 23, 59, 59),
      actionUrl: null,
      actionType: 'none',
    );

    if (!ad.isCurrentlyValid) return null;
    return ad;
  }
}

final launchPromoRepositoryProvider = Provider<LaunchPromoRepository>((ref) {
  return LaunchPromoRepository();
});

final skipTimerPromoProvider = FutureProvider<SkipTimerPromo>((ref) {
  return ref.watch(launchPromoRepositoryProvider).fetchSkipTimerPromo();
});

final networkNoticeProvider = FutureProvider<Advertisement?>((ref) {
  return ref.watch(launchPromoRepositoryProvider).fetchNetworkNotice();
});

final activeAdvertisementProvider = FutureProvider<Advertisement?>((ref) {
  return ref.watch(launchPromoRepositoryProvider).fetchActiveAdvertisement();
});

/// When true, [HomePage] presents launch notice + promotion modals once after open.
final pendingLaunchPromotionProvider = StateProvider<bool>((ref) => false);
