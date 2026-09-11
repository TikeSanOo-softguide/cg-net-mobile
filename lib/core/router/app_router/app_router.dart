import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/bottom_nav_bar/bottom_nav_bar.dart';
import '../../../pages/auth/login/login_page.dart';
import '../../../pages/auth/onboarding/onboarding_page.dart';
import '../../../pages/auth/otp_success/otp_success_page.dart';
import '../../../pages/auth/otp_verification/otp_verification_page.dart';
import '../../../pages/auth/set_username_password/set_username_password_page.dart';
import '../../../pages/auth/splash/splash_page.dart';
import '../../../pages/auth/terms/terms_page.dart';
import '../../../pages/home/home/home_page.dart';
import '../../../pages/inbox/inbox_detail/inbox_detail_page.dart';
import '../../../pages/inbox/inbox_list/inbox_list_page.dart';
import '../../../pages/launch/advertisement/advertisement_page.dart';
import '../../../pages/launch/skip_timer_image/skip_timer_image_page.dart';
import '../../../pages/package/package_list/package_list_page.dart';
import '../../../pages/profile/about_app/about_app_page.dart';
import '../../../pages/profile/change_password/change_password_page.dart';
import '../../../pages/profile/device_session/device_session_page.dart';
import '../../../pages/profile/edit_profile/edit_profile_page.dart';
import '../../../pages/profile/language_settings/language_settings_page.dart';
import '../../../pages/profile/notification_preferences/notification_preferences_page.dart';
import '../../../pages/profile/profile/profile_page.dart';
import '../../../pages/shared_pages/error_no_internet/error_no_internet_page.dart';
import '../../../pages/shared_pages/force_update/force_update_page.dart';
import '../../../pages/shared_pages/not_found/not_found_page.dart';
import '../../../pages/support/support_chat/support_chat_page.dart';
import '../../storage/secure_storage/secure_storage.dart';
import '../route_names/route_names.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final hasToken = await secureStorage.hasToken();

      final isPublic = loc == RoutePaths.splash ||
          loc == RoutePaths.onboarding ||
          loc == RoutePaths.login ||
          loc == RoutePaths.terms ||
          loc.startsWith('/otp') ||
          loc.startsWith('/set-username') ||
          loc.startsWith('/error') ||
          loc == RoutePaths.notFound;

      if (!hasToken && !isPublic) {
        return RoutePaths.login;
      }

      final isAuthOnly = loc == RoutePaths.login ||
          loc == RoutePaths.onboarding ||
          loc.startsWith('/otp') ||
          loc.startsWith('/set-username');
      if (hasToken && isAuthOnly) {
        return RoutePaths.home;
      }
      return null;
    },
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.terms,
        name: RouteNames.terms,
        builder: (context, state) => const TermsPage(),
      ),
      GoRoute(
        path: RoutePaths.otpVerification,
        name: RouteNames.otpVerification,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpVerificationPage(phone: phone);
        },
      ),
      GoRoute(
        path: RoutePaths.otpSuccess,
        name: RouteNames.otpSuccess,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpSuccessPage(phone: phone);
        },
      ),
      GoRoute(
        path: RoutePaths.setUsernamePassword,
        name: RouteNames.setUsernamePassword,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return SetUsernamePasswordPage(phone: phone);
        },
      ),
      GoRoute(
        path: RoutePaths.skipTimerImage,
        name: RouteNames.skipTimerImage,
        builder: (context, state) => const SkipTimerImagePage(),
      ),
      GoRoute(
        path: RoutePaths.advertisement,
        name: RouteNames.advertisement,
        builder: (context, state) => const AdvertisementPage(),
      ),
      GoRoute(
        path: RoutePaths.errorNoInternet,
        name: RouteNames.errorNoInternet,
        builder: (context, state) => const ErrorNoInternetPage(),
      ),
      GoRoute(
        path: RoutePaths.forceUpdate,
        name: RouteNames.forceUpdate,
        builder: (context, state) => const ForceUpdatePage(),
      ),
      GoRoute(
        path: RoutePaths.notFound,
        name: RouteNames.notFound,
        builder: (context, state) => const NotFoundPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.packageList,
                name: RouteNames.packageList,
                builder: (context, state) => const PackageListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.inboxList,
                name: RouteNames.inboxList,
                builder: (context, state) => const InboxListPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: RouteNames.inboxDetail,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return InboxDetailPage(id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.supportChat,
                name: RouteNames.supportChat,
                builder: (context, state) => const SupportChatPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfilePage(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    name: RouteNames.editProfile,
                    builder: (context, state) => const EditProfilePage(),
                  ),
                  GoRoute(
                    path: 'language',
                    name: RouteNames.languageSettings,
                    builder: (context, state) => const LanguageSettingsPage(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    name: RouteNames.changePassword,
                    builder: (context, state) => const ChangePasswordPage(),
                  ),
                  GoRoute(
                    path: 'devices',
                    name: RouteNames.deviceSession,
                    builder: (context, state) => const DeviceSessionPage(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: RouteNames.notificationPreferences,
                    builder: (context, state) =>
                        const NotificationPreferencesPage(),
                  ),
                  GoRoute(
                    path: 'about',
                    name: RouteNames.aboutApp,
                    builder: (context, state) => const AboutAppPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
