import 'package:cg_net_mobile/core/router/route_names/route_names.dart';
import 'package:cg_net_mobile/core/router/route_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('route policy', () {
    test('public locations include auth and error routes', () {
      expect(isPublicRouteLocation(RoutePaths.login), isTrue);
      expect(isPublicRouteLocation(RoutePaths.loginQa), isTrue);
      expect(isPublicRouteLocation(RoutePaths.terms), isTrue);
      expect(isPublicRouteLocation(RoutePaths.errorNoInternet), isTrue);
      expect(isPublicRouteLocation(RoutePaths.home), isFalse);
    });

    test('auth only locations include onboarding and otp paths', () {
      expect(isAuthOnlyRouteLocation(RoutePaths.onboarding), isTrue);
      expect(isAuthOnlyRouteLocation('/otp-verification'), isTrue);
      expect(isAuthOnlyRouteLocation('/set-username-password'), isTrue);
      expect(isAuthOnlyRouteLocation(RoutePaths.home), isFalse);
    });

    test('loginWithSessionExpiredReason builds expected query', () {
      expect(
        loginWithSessionExpiredReason(),
        '${RoutePaths.login}?$sessionReasonKey=$sessionExpiredReason',
      );
    });
  });
}
