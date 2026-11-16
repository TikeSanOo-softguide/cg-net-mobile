import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../components/activity_list_card/activity_list_card.dart';
import '../../../components/bottom_nav_bar/bottom_nav_bar.dart';
import '../../../pages/auth/login/login_page.dart';
import '../../../pages/auth/login/login_qa_page.dart';
import '../../../pages/auth/onboarding/onboarding_page.dart';
import '../../../pages/auth/otp_success/otp_success_page.dart';
import '../../../pages/auth/otp_verification/otp_verification_page.dart';
import '../../../pages/auth/password_login/password_login_page.dart';
import '../../../pages/auth/set_username_password/set_username_password_page.dart';
import '../../../pages/auth/splash/splash_page.dart';
import '../../../pages/auth/terms/terms_page.dart';
import '../../../pages/home/activity_detail/activity_detail_page.dart';
import '../../../pages/home/history/history_page.dart';
import '../../../pages/home/bind_broadband/bind_broadband_page.dart';
import '../../../pages/home/home/home_page.dart';
import '../../../pages/home/subscription_detail/subscription_detail_page.dart';
import '../../../pages/home/service_placeholder/service_placeholder_page.dart';
import '../../../pages/home/top_up/top_up_failure_page.dart';
import '../../../pages/home/top_up/top_up_page.dart';
import '../../../pages/home/top_up/top_up_pending_page.dart';
import '../../../pages/home/top_up/top_up_result.dart';
import '../../../pages/home/pay_bill/pay_bill_pending_page.dart';
import '../../../pages/home/pay_bill/pay_bill_result.dart';
import '../../../pages/home/pay_bill/pay_bill_success_page.dart';
import '../../../pages/home/top_up/top_up_success_page.dart';
import '../../../pages/inbox/inbox_detail/inbox_detail_page.dart';
import '../../../pages/inbox/inbox_list/inbox_list_page.dart';
import '../../../pages/launch/advertisement/advertisement_page.dart';
import '../../../pages/launch/skip_timer_image/skip_timer_image_page.dart';
import '../../../pages/package/package_detail/package_buy_failure_page.dart';
import '../../../pages/package/package_detail/package_buy_result.dart';
import '../../../pages/package/package_detail/package_buy_success_page.dart';
import '../../../pages/package/package_detail/package_detail_page.dart';
import '../../../pages/package/package_list/package_list_page.dart';
import '../../../pages/profile/about_app/about_app_page.dart';
import '../../../pages/profile/change_password/change_password_page.dart';
import '../../../pages/profile/change_password/verify_change_password_otp_page.dart';
import '../../../pages/profile/deactivate_account/deactivate_account_page.dart';
import '../../../pages/profile/edit_profile/edit_profile_page.dart';
import '../../../pages/profile/notification_preferences/notification_preferences_page.dart';
import '../../../pages/profile/profile/profile_page.dart';
import '../../../pages/shared_pages/error_no_internet/error_no_internet_page.dart';
import '../../../pages/shared_pages/force_update/force_update_page.dart';
import '../../../pages/shared_pages/not_found/not_found_page.dart';
import '../../../pages/support/support_chat/support_chat_page.dart';
import '../../../models/change_password_model/change_password_otp_session.dart';
import '../../network/session_clock.dart';
import '../../storage/secure_storage/secure_storage.dart';
import '../route_names/route_names.dart';
import '../route_policy.dart';
import '../slide_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final secureStorage = ref.read(secureStorageProvider);
  final session = ref.read(sessionClockProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: session,
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      final hasToken = await secureStorage.hasToken();

      final isPublic = isPublicRouteLocation(loc);

      if (!hasToken && !isPublic) {
        if (session.expiredByUnauthorized) {
          final consumed = session.consumeUnauthorizedExpiration();
          if (consumed) {
            return loginWithSessionExpiredReason();
          }
        }
        return RoutePaths.login;
      }

      final isAuthOnly = isAuthOnlyRouteLocation(loc);
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
        path: RoutePaths.loginQa,
        name: RouteNames.loginQa,
        builder: (context, state) => const LoginQaPage(),
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
          final challengeId = state.uri.queryParameters['challenge_id'] ?? '';
          final resendAfter = int.tryParse(
                state.uri.queryParameters['resend_after'] ?? '',
              ) ??
              60;
          return OtpVerificationPage(
            phone: phone,
            challengeId: challengeId,
            resendAfter: resendAfter,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.otpSuccess,
        name: RouteNames.otpSuccess,
        builder: (context, state) => OtpSuccessPage(
          phone: state.uri.queryParameters['phone'] ?? '',
          verificationToken:
              state.uri.queryParameters['verification_token'] ?? '',
        ),
      ),
      GoRoute(
        path: RoutePaths.setUsernamePassword,
        name: RouteNames.setUsernamePassword,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final verificationToken =
              state.uri.queryParameters['verification_token'] ?? '';
          return SetUsernamePasswordPage(
            phone: phone,
            verificationToken: verificationToken,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.passwordLogin,
        name: RouteNames.passwordLogin,
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          final verificationToken =
              state.uri.queryParameters['verification_token'] ?? '';
          return PasswordLoginPage(
            phone: phone,
            verificationToken: verificationToken,
          );
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
        builder: (context, state) {
          final returnTo = state.uri.queryParameters['return_to'];
          return ErrorNoInternetPage(returnToPath: returnTo);
        },
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
      // Full-screen pages above the bottom-nav shell (avoids blank shell child).
      GoRoute(
        path: RoutePaths.bindBroadband,
        name: RouteNames.bindBroadband,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => slidePage(
          key: state.pageKey,
          child: const BindBroadbandPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.topUp,
        name: RouteNames.topUp,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => slidePage(
          key: state.pageKey,
          child: const TopUpPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.topUpSuccess,
        name: RouteNames.topUpSuccess,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra;
          final Widget child;
          if (result is! TopUpResult ||
              result.status != TopUpTxnStatus.success) {
            child = const NotFoundPage();
          } else {
            child = TopUpSuccessPage(
              result: result,
              showPrimary: state.uri.queryParameters['hideDone'] != '1',
            );
          }
          return slidePage<void>(
            key: state.pageKey,
            child: child,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.topUpFailure,
        name: RouteNames.topUpFailure,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra;
          final Widget child;
          if (result is! TopUpResult ||
              result.status != TopUpTxnStatus.failure) {
            child = const NotFoundPage();
          } else {
            child = TopUpFailurePage(result: result);
          }
          return slidePage(key: state.pageKey, child: child);
        },
      ),
      GoRoute(
        path: RoutePaths.topUpPending,
        name: RouteNames.topUpPending,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra;
          final Widget child;
          if (result is! TopUpResult ||
              result.status != TopUpTxnStatus.pending) {
            child = const NotFoundPage();
          } else {
            child = TopUpPendingPage(result: result);
          }
          return slidePage(key: state.pageKey, child: child);
        },
      ),
      GoRoute(
        path: RoutePaths.history,
        name: RouteNames.history,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => slidePage(
          key: state.pageKey,
          child: const HistoryPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.activityDetail,
        name: RouteNames.activityDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final item = state.extra;
          final Widget child;
          if (item is! ActivityItem) {
            child = const NotFoundPage();
          } else {
            child = ActivityDetailPage(item: item);
          }
          return slidePage(key: state.pageKey, child: child);
        },
      ),
      GoRoute(
        path: RoutePaths.servicePlaceholder,
        name: RouteNames.servicePlaceholder,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return slidePage(
            key: state.pageKey,
            child: ServicePlaceholderPage(serviceId: id),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.subscriptionDetail,
        name: RouteNames.subscriptionDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) => slidePage(
          key: state.pageKey,
          child: const SubscriptionDetailPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.packageDetail,
        name: RouteNames.packageDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return slidePage(
            key: state.pageKey,
            child: PackageDetailPage(packageId: id),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.packageBuySuccess,
        name: RouteNames.packageBuySuccess,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra;
          final Widget child;
          if (result is! PackageBuyResult ||
              result.status != PackageBuyTxnStatus.success) {
            child = const NotFoundPage();
          } else {
            child = PackageBuySuccessPage(
              result: result,
              showPrimary: state.uri.queryParameters['hideDone'] != '1',
            );
          }
          return slidePage<void>(
            key: state.pageKey,
            child: child,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.packageBuyFailure,
        name: RouteNames.packageBuyFailure,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra;
          final Widget child;
          if (result is! PackageBuyResult ||
              result.status != PackageBuyTxnStatus.failure) {
            child = const NotFoundPage();
          } else {
            child = PackageBuyFailurePage(result: result);
          }
          return slidePage(key: state.pageKey, child: child);
        },
      ),
      GoRoute(
        path: RoutePaths.payBillSuccess,
        name: RouteNames.payBillSuccess,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra;
          final Widget child;
          if (result is! PayBillResult ||
              result.status != PayBillTxnStatus.success) {
            child = const NotFoundPage();
          } else {
            child = PayBillSuccessPage(
              result: result,
              showPrimary: state.uri.queryParameters['hideDone'] != '1',
            );
          }
          return slidePage<void>(
            key: state.pageKey,
            child: child,
          );
        },
      ),
      GoRoute(
        path: RoutePaths.payBillPending,
        name: RouteNames.payBillPending,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (context, state) {
          final result = state.extra;
          final Widget child;
          if (result is! PayBillResult ||
              result.status != PayBillTxnStatus.pending) {
            child = const NotFoundPage();
          } else {
            child = PayBillPendingPage(result: result);
          }
          return slidePage(key: state.pageKey, child: child);
        },
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
                    pageBuilder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return slidePage(
                        key: state.pageKey,
                        child: InboxDetailPage(id: id),
                      );
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
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => slidePage(
                      key: state.pageKey,
                      child: const EditProfilePage(),
                    ),
                  ),
                  GoRoute(
                    path: 'deactivate-account',
                    name: RouteNames.deactivateAccount,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => slidePage(
                      key: state.pageKey,
                      child: const DeactivateAccountPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'change-password',
                    name: RouteNames.changePassword,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => slidePage(
                      key: state.pageKey,
                      child: const ChangePasswordPage(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'verify-otp',
                        name: RouteNames.verifyChangePasswordOtp,
                        parentNavigatorKey: _rootNavigatorKey,
                        pageBuilder: (context, state) {
                          final session = state.extra;
                          final Widget child;
                          if (session is! ChangePasswordOtpSession) {
                            child = const NotFoundPage();
                          } else {
                            child = VerifyChangePasswordOtpPage(
                              session: session,
                            );
                          }
                          return slidePage(key: state.pageKey, child: child);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'notifications',
                    name: RouteNames.notificationPreferences,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => slidePage(
                      key: state.pageKey,
                      child: const NotificationPreferencesPage(),
                    ),
                  ),
                  GoRoute(
                    path: 'about',
                    name: RouteNames.aboutApp,
                    parentNavigatorKey: _rootNavigatorKey,
                    pageBuilder: (context, state) => slidePage(
                      key: state.pageKey,
                      child: const AboutAppPage(),
                    ),
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
