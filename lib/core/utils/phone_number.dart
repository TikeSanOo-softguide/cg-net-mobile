/// Canonical phone helpers — keep in sync with backend `App\Support\PhoneNumber`
/// and admin `resources/js/lib/phone.ts`.
class PhoneNumber {
  PhoneNumber._();

  /// Supported app countries only (canonical digits, no "+").
  static final RegExp supportedPattern = RegExp(
    r'^(959[2-9]\d{7,10}|66(?:14\d{7}|[689]\d{8})|861[3-9]\d{9})$',
  );

  static final RegExp _generalPattern = RegExp(r'^[1-9][0-9]{7,14}$');

  /// Digits-only country code first (e.g. `959223456789`), or `null` if invalid.
  static String? normalize(String phone) {
    var value = phone.trim().replaceAll(RegExp(r'[\s().-]+'), '');

    if (value.startsWith('00')) {
      value = '+${value.substring(2)}';
    }

    if (value.startsWith('09')) {
      value = '+95${value.substring(1)}';
    } else if (value.startsWith('06') || value.startsWith('08')) {
      value = '+66${value.substring(1)}';
    }

    value = value.replaceFirst(RegExp(r'^\++'), '');

    if (value.startsWith('950')) {
      value = '95${value.substring(3)}';
    } else if (value.startsWith('660')) {
      value = '66${value.substring(3)}';
    }

    if (!_generalPattern.hasMatch(value)) {
      return null;
    }

    return value;
  }

  static bool isSupported(String normalized) =>
      supportedPattern.hasMatch(normalized);

  /// Validates dial code + local digits the same way OTP request does.
  ///
  /// Returns an error message key path when invalid, otherwise `null`.
  static String? validationErrorKey({
    required String dialCode,
    required String? localInput,
  }) {
    final digits = (localInput ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return 'login.phone_required';
    }
    if (digits.length < 8) {
      return 'login.phone_invalid';
    }

    final normalized = normalize('$dialCode$digits');
    if (normalized == null || !isSupported(normalized)) {
      return 'login.phone_unsupported';
    }

    return null;
  }

  /// Full number for API (`+959…`), or `null` when invalid.
  static String? toApiPhone({
    required String dialCode,
    required String localInput,
  }) {
    final digits = localInput.replaceAll(RegExp(r'\D'), '');
    final normalized = normalize('$dialCode$digits');
    if (normalized == null || !isSupported(normalized)) {
      return null;
    }
    return '+$normalized';
  }
}
