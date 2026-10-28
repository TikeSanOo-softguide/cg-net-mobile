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
  static const authLoggedOut = 'MSG-AUTH-019';
  static const authAccountDeactivated = 'MSG-AUTH-020';

  static const apiNetworkFailed = 'MSG-API-001';
  static const apiTimeout = 'MSG-API-002';
  static const apiCancelled = 'MSG-API-003';

  static const sysUnexpected = 'MSG-SYS-001';

  static const bbConnectionFailed = 'MSG-BB-001';
  static const bbNotMatch = 'MSG-BB-002';
  static const bbAlreadyConnected = 'MSG-BB-003';
  static const bbDifferentAccount = 'MSG-BB-004';
  static const bbInUse = 'MSG-BB-005';
  static const bbConnected = 'MSG-BB-006';
  static const bbDisconnected = 'MSG-BB-007';
  static const bbFound = 'MSG-BB-008';
  static const bbUpstreamFailed = 'MSG-BB-009';

  static const topupValid = 'MSG-TOPUP-001';
  static const topupAlreadyUsed = 'MSG-TOPUP-002';
  static const topupInvalid = 'MSG-TOPUP-003';
  static const topupAccountNotFound = 'MSG-TOPUP-004';
  static const topupAccountUnavailable = 'MSG-TOPUP-005';
  static const topupWalletNotFound = 'MSG-TOPUP-006';
  static const topupWalletInactive = 'MSG-TOPUP-007';
  static const topupCardInvalid = 'MSG-TOPUP-008';
  static const topupActionIncomplete = 'MSG-TOPUP-009';
  static const topupSuccess = 'MSG-TOPUP-010';
  static const topupRequestIncomplete = 'MSG-TOPUP-011';
  static const topupTooManyUser = 'MSG-TOPUP-012';
  static const topupTooManyIp = 'MSG-TOPUP-013';
  static const topupAlreadyProcessed = 'MSG-TOPUP-014';
  static const topupSerialThrottled = 'MSG-TOPUP-015';

  static const pkgWalletNotFound = 'MSG-PKG-001';
  static const pkgWalletInactive = 'MSG-PKG-002';
  static const pkgCatalogUnavailable = 'MSG-PKG-003';
  static const pkgCompletionPending = 'MSG-PKG-004';
  static const pkgPurchased = 'MSG-PKG-005';
  static const pkgAlreadyProcessed = 'MSG-PKG-006';
  static const pkgActivationRefunded = 'MSG-PKG-007';
  static const pkgProcessing = 'MSG-PKG-008';
  static const pkgReconciliationPending = 'MSG-PKG-009';
  static const pkgInsufficientBalance = 'MSG-PKG-010';
  static const pkgKeyUsed = 'MSG-PKG-011';
  static const pkgKeyMismatch = 'MSG-PKG-012';
  static const pkgCannotReplay = 'MSG-PKG-013';

  static const pwdChanged = 'MSG-PWD-001';
  static const pwdChangeExpired = 'MSG-PWD-002';

  static const devRegistered = 'MSG-DEV-001';
  static const devRemoved = 'MSG-DEV-002';

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
    authLoggedOut,
    authAccountDeactivated,
    apiNetworkFailed,
    apiTimeout,
    apiCancelled,
    sysUnexpected,
    bbConnectionFailed,
    bbNotMatch,
    bbAlreadyConnected,
    bbDifferentAccount,
    bbInUse,
    bbConnected,
    bbDisconnected,
    bbFound,
    bbUpstreamFailed,
    topupValid,
    topupAlreadyUsed,
    topupInvalid,
    topupAccountNotFound,
    topupAccountUnavailable,
    topupWalletNotFound,
    topupWalletInactive,
    topupCardInvalid,
    topupActionIncomplete,
    topupSuccess,
    topupRequestIncomplete,
    topupTooManyUser,
    topupTooManyIp,
    topupAlreadyProcessed,
    topupSerialThrottled,
    pkgWalletNotFound,
    pkgWalletInactive,
    pkgCatalogUnavailable,
    pkgCompletionPending,
    pkgPurchased,
    pkgAlreadyProcessed,
    pkgActivationRefunded,
    pkgProcessing,
    pkgReconciliationPending,
    pkgInsufficientBalance,
    pkgKeyUsed,
    pkgKeyMismatch,
    pkgCannotReplay,
    pwdChanged,
    pwdChangeExpired,
    devRegistered,
    devRemoved,
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
