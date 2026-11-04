import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivePlan {
  const ActivePlan({
    required this.id,
    required this.titleKey,
    required this.expiry,
    required this.username,
    required this.password,
  });

  final String id;
  final String titleKey;
  final String expiry;
  final String username;
  final String password;
}

class HomeDashboardData {
  const HomeDashboardData({
    required this.accountNumber,
    required this.balanceLabel,
    required this.balanceAmount,
    required this.plans,
  });

  final String accountNumber;
  final String balanceLabel;
  final String balanceAmount;
  final List<ActivePlan> plans;
}

class HomeController extends StateNotifier<HomeDashboardData> {
  HomeController()
      : super(
          const HomeDashboardData(
            accountNumber: '09970071489',
            balanceLabel: '1250',
            balanceAmount: '1250',
            plans: [
              ActivePlan(
                id: '1m',
                titleKey: 'package.item_1m_title',
                expiry: '2026.12.15',
                username: 'cgnet_user',
                password: 'cgnet1234',
              ),
              ActivePlan(
                id: '3m',
                titleKey: 'package.item_3m_title',
                expiry: '2027.02.01',
                username: 'cgnet_home',
                password: 'home8899',
              ),
              ActivePlan(
                id: '6m',
                titleKey: 'package.item_6m_title',
                expiry: '2027.05.01',
                username: 'cgnet_shop',
                password: 'shop5566',
              ),
            ],
          ),
        );
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeDashboardData>((ref) {
  return HomeController();
});
