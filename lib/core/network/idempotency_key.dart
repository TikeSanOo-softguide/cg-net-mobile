class IdempotencyKey {
  IdempotencyKey._();

  static String forTopUp({required String phone}) {
    final seed = _digitsOnly(phone);
    return _build('topup', seed.isEmpty ? 'unknown' : seed);
  }

  static String forPackageBuy({required String packageId}) {
    return _build('package-buy', packageId);
  }

  static String _build(String scope, String identifier) {
    final millis = DateTime.now().millisecondsSinceEpoch;
    return '$scope-$identifier-$millis';
  }

  static String _digitsOnly(String input) {
    return input.replaceAll(RegExp(r'\D'), '');
  }
}
