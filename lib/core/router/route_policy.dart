import 'route_names/route_names.dart';

const sessionReasonKey = 'reason';
const sessionExpiredReason = 'session_expired';

bool isPublicRouteLocation(String location) {
  return location == RoutePaths.splash ||
      location == RoutePaths.onboarding ||
      location == RoutePaths.login ||
      location == RoutePaths.loginQa ||
      location == RoutePaths.terms ||
      location.startsWith('/otp') ||
      location.startsWith('/set-username') ||
      location == RoutePaths.passwordLogin ||
      location.startsWith('/error') ||
      location == RoutePaths.notFound;
}

bool isAuthOnlyRouteLocation(String location) {
  return location == RoutePaths.login ||
      location == RoutePaths.loginQa ||
      location == RoutePaths.onboarding ||
      location == RoutePaths.terms ||
      location.startsWith('/otp') ||
      location.startsWith('/set-username') ||
      location == RoutePaths.passwordLogin;
}

String loginWithSessionExpiredReason() {
  return '${RoutePaths.login}?$sessionReasonKey=$sessionExpiredReason';
}
