import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.accountNumber,
    required this.balanceLabel,
    required this.balanceAmount,
    required this.packageId,
    required this.packageImagePath,
    required this.planTitleKey,
    required this.planExpiry,
    required this.username,
    required this.password,
    this.validityDays = 30,
  });

  final String accountNumber;
  final String balanceLabel;
  final String balanceAmount;
  /// Purchased package id (same as home offers / catalog).
  final String packageId;
  final String packageImagePath;
  final String planTitleKey;
  final String planExpiry;
  final String username;
  final String password;
  final int validityDays;
}

class HomeController extends StateNotifier<HomeDashboardData> {
  HomeController()
      : super(
          const HomeDashboardData(
            accountNumber: '09970071489',
            balanceLabel: '25000',
            balanceAmount: '25000',
            packageId: '1m',
            packageImagePath: 'assets/images/packages/package_1m.png',
            planTitleKey: 'package.item_1m_title',
            planExpiry: '2026.10.15',
            username: 'cgnet_user',
            password: 'cgnet1234',
            validityDays: 30,
          ),
        );
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeDashboardData>((ref) {
  return HomeController();
});
