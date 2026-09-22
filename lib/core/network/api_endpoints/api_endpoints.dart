class ApiEndpoints {
  ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const String availablePlans = '/v1/customer/plans/available';
  static const String sendOtp = '/api/auth/otp/request';
  static const String verifyOtp = '/api/auth/otp/verify';
  static const String resendOtp = '/api/auth/otp/resend';
  static const String profile = '/v1/customer/profile';
  static const String inbox = '/v1/customer/inbox';
  static const String supportChats = '/v1/customer/support/chats';
}
