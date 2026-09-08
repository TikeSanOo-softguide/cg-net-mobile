class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const String availablePlans = '/v1/customer/plans/available';
  static const String sendOtp = '/v1/customer/auth/otp/send';
  static const String verifyOtp = '/v1/customer/auth/otp/verify';
  static const String setCredentials = '/v1/customer/auth/credentials';
  static const String profile = '/v1/customer/profile';
  static const String inbox = '/v1/customer/inbox';
  static const String supportChats = '/v1/customer/support/chats';
}
