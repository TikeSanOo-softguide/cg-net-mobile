/// Server-confirmed top-up transaction result (never includes PIN).
enum TopUpTxnStatus { success, failure, pending }

class TopUpResult {
  const TopUpResult({
    required this.status,
    required this.amountPoints,
    required this.serialMasked,
    required this.transactionId,
    required this.occurredAt,
    this.errorTitleKey,
    this.errorBodyKey,
    this.errorTitle,
    this.errorBody,
    this.browseMode = false,
  });

  final TopUpTxnStatus status;
  final int amountPoints;
  final String serialMasked;
  final String transactionId;
  final DateTime occurredAt;

  /// Localization keys for failure copy (preferred).
  final String? errorTitleKey;
  final String? errorBodyKey;

  /// Server-safe plain strings when keys are not used.
  final String? errorTitle;
  final String? errorBody;

  /// Opened from Top Up / History list (detail browse, not post-submit).
  final bool browseMode;

  static String maskSerial(String serial) {
    final s = serial.trim();
    if (s.length < 8) return '****';
    return '${s.substring(0, 4)}****${s.substring(s.length - 4)}';
  }

  factory TopUpResult.success({
    required int amountPoints,
    required String serialRaw,
    required String transactionId,
    DateTime? occurredAt,
  }) {
    return TopUpResult(
      status: TopUpTxnStatus.success,
      amountPoints: amountPoints,
      serialMasked: maskSerial(serialRaw),
      transactionId: transactionId,
      occurredAt: occurredAt ?? DateTime.now(),
    );
  }

  factory TopUpResult.failure({
    required int amountPoints,
    required String serialRaw,
    required String transactionId,
    DateTime? occurredAt,
    String? errorTitleKey,
    String? errorBodyKey,
    String? errorTitle,
    String? errorBody,
  }) {
    return TopUpResult(
      status: TopUpTxnStatus.failure,
      amountPoints: amountPoints,
      serialMasked: maskSerial(serialRaw),
      transactionId: transactionId,
      occurredAt: occurredAt ?? DateTime.now(),
      errorTitleKey: errorTitleKey,
      errorBodyKey: errorBodyKey,
      errorTitle: errorTitle,
      errorBody: errorBody,
    );
  }

  factory TopUpResult.pending({
    required int amountPoints,
    required String serialRaw,
    required String transactionId,
    DateTime? occurredAt,
  }) {
    return TopUpResult(
      status: TopUpTxnStatus.pending,
      amountPoints: amountPoints,
      serialMasked: maskSerial(serialRaw),
      transactionId: transactionId,
      occurredAt: occurredAt ?? DateTime.now(),
    );
  }

  /// Browse an activity list top-up row on the Top Up Detail page.
  factory TopUpResult.fromActivityAmount({
    required int amountPoints,
    required String transactionId,
    required DateTime occurredAt,
    String serialRaw = '1234567890123456',
  }) {
    return TopUpResult(
      status: TopUpTxnStatus.success,
      amountPoints: amountPoints,
      serialMasked: maskSerial(serialRaw),
      transactionId: transactionId,
      occurredAt: occurredAt,
      browseMode: true,
    );
  }
}
