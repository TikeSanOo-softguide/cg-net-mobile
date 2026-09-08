import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeDashboardData {
  const HomeDashboardData({
    required this.accountNumber,
    required this.balanceLabel,
    required this.balanceAmount,
    required this.planTitle,
    required this.planExpiry,
    required this.username,
    required this.password,
  });

  final String accountNumber;
  final String balanceLabel;
  final String balanceAmount;
  final String planTitle;
  final String planExpiry;
  final String username;
  final String password;
}

class HomeController extends StateNotifier<HomeDashboardData> {
  HomeController()
      : super(
          const HomeDashboardData(
            accountNumber: '09970071489',
            balanceLabel: '25000',
            balanceAmount: '25000',
            planTitle: 'Unlimited Data',
            planExpiry: '31 Aug 2024',
            username: 'cgnet_user',
            password: '********',
          ),
        );
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeDashboardData>((ref) {
  return HomeController();
});
