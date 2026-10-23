/// Auth + transport message codes. Keep in sync with backend `App\Enums\MessageCode`.
///
/// Backend sends `code` (this string). Mobile shows `locKey(code).tr()`.
/// MSG-AUTH-002 is success, not an error. MSG-AUTH-003 is unused (no username).
/// MSG-USER-001 is unused on login so the API does not leak account existence.
class MessageCodes {
  MessageCodes._();

  static const authIncorrectPassword = 'MSG-AUTH-001';
  static const authAccountLocked = 'MSG-AUTH-004';
  static const authOtpFailed = 'MSG-AUTH-005';
  static const authPhoneUnsupported = 'MSG-AUTH-006';
  static const authPhoneRequired = 'MSG-AUTH-007';
  static const authOtpResendCooldown = 'MSG-AUTH-008';
  static const authOtpTooManyRequests = 'MSG-AUTH-009';
  static const authVerificationTokenInvalid = 'MSG-AUTH-010';
  static const authLoginTooManyAttempts = 'MSG-AUTH-011';
  static const authAlreadySignedIn = 'MSG-AUTH-012';
  static const authRegistrationInUse = 'MSG-AUTH-013';
  static const authAccountRestricted = 'MSG-AUTH-014';
  static const authOtpVerifyInProgress = 'MSG-AUTH-015';
  static const authRegistrationInProgress = 'MSG-AUTH-016';
  static const authSessionExpired = 'MSG-AUTH-017';
  static const authTooManyRequests = 'MSG-AUTH-018';

  static const apiNetworkFailed = 'MSG-API-001';
  static const apiTimeout = 'MSG-API-002';
  static const apiCancelled = 'MSG-API-003';

  static const sysUnexpected = 'MSG-SYS-001';

  static const Set<String> known = {
    authIncorrectPassword,
    authAccountLocked,
    authOtpFailed,
    authPhoneUnsupported,
    authPhoneRequired,
    authOtpResendCooldown,
    authOtpTooManyRequests,
    authVerificationTokenInvalid,
    authLoginTooManyAttempts,
    authAlreadySignedIn,
    authRegistrationInUse,
    authAccountRestricted,
    authOtpVerifyInProgress,
    authRegistrationInProgress,
    authSessionExpired,
    authTooManyRequests,
    apiNetworkFailed,
    apiTimeout,
    apiCancelled,
    sysUnexpected,
  };

  /// `MSG-AUTH-001` → `msg.auth_001`
  static String locKey(String code) {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.startsWith('MSG-')) {
      return 'msg.${trimmed.substring(4).toLowerCase().replaceAll('-', '_')}';
    }
    return 'msg.sys_001';
  }

  static bool isKnown(String? code) {
    if (code == null || code.trim().isEmpty) return false;
    return known.contains(code.trim().toUpperCase());
  }
}
