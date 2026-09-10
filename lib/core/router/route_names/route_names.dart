class RouteNames {
  RouteNames._();

  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const terms = 'terms';
  static const otpVerification = 'otpVerification';
  static const otpSuccess = 'otpSuccess';
  static const setUsernamePassword = 'setUsernamePassword';

  static const home = 'home';
  static const packageList = 'packageList';
  static const inboxList = 'inboxList';
  static const inboxDetail = 'inboxDetail';
  static const supportChat = 'supportChat';

  static const profile = 'profile';
  static const editProfile = 'editProfile';
  static const languageSettings = 'languageSettings';
  static const changePassword = 'changePassword';
  static const deviceSession = 'deviceSession';
  static const notificationPreferences = 'notificationPreferences';
  static const aboutApp = 'aboutApp';

  static const errorNoInternet = 'errorNoInternet';
  static const forceUpdate = 'forceUpdate';
  static const notFound = 'notFound';
}

class RoutePaths {
  RoutePaths._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const terms = '/terms';
  static const otpVerification = '/otp-verification';
  static const otpSuccess = '/otp-success';
  static const setUsernamePassword = '/set-username-password';

  static const home = '/home';
  static const packageList = '/package';
  static const inboxList = '/inbox';
  static const inboxDetail = '/inbox/:id';
  static const supportChat = '/support';

  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const languageSettings = '/profile/language';
  static const changePassword = '/profile/change-password';
  static const deviceSession = '/profile/devices';
  static const notificationPreferences = '/profile/notifications';
  static const aboutApp = '/profile/about';

  static const errorNoInternet = '/error/no-internet';
  static const forceUpdate = '/error/force-update';
  static const notFound = '/404';
}
