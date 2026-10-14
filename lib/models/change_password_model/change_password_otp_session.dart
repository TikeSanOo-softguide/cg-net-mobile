import 'change_password_model.dart';

class ChangePasswordChallenge {
  const ChangePasswordChallenge({
    required this.challengeId,
    this.debugOtp,
    this.resendAfter = 60,
  });

  final String challengeId;
  final String? debugOtp;
  final int resendAfter;
}

class ChangePasswordOtpSession {
  ChangePasswordOtpSession({
    required this.challenge,
    required this.password,
  });

  final ChangePasswordChallenge challenge;
  ChangePasswordModel? password;

  void clearPassword() {
    password = null;
  }
}
