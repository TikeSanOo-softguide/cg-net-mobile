enum TransferTxnStatus { success, failure }

enum TransferFailureReason { wrongPassword, insufficientPoints, other }

class TransferResult {
  const TransferResult({
    required this.status,
    required this.amountPoints,
    required this.recipientAccount,
    required this.transactionId,
    required this.occurredAt,
    this.failureReason,
    this.errorTitleKey,
    this.errorBodyKey,
  });

  final TransferTxnStatus status;
  final int amountPoints;
  final String recipientAccount;
  final String transactionId;
  final DateTime occurredAt;
  final TransferFailureReason? failureReason;
  final String? errorTitleKey;
  final String? errorBodyKey;

  factory TransferResult.success({
    required int amountPoints,
    required String recipientAccount,
    required String transactionId,
    DateTime? occurredAt,
  }) {
    return TransferResult(
      status: TransferTxnStatus.success,
      amountPoints: amountPoints,
      recipientAccount: recipientAccount,
      transactionId: transactionId,
      occurredAt: occurredAt ?? DateTime.now(),
    );
  }

  factory TransferResult.failure({
    required int amountPoints,
    required String recipientAccount,
    required String transactionId,
    required TransferFailureReason failureReason,
    DateTime? occurredAt,
    String? errorTitleKey,
    String? errorBodyKey,
  }) {
    return TransferResult(
      status: TransferTxnStatus.failure,
      amountPoints: amountPoints,
      recipientAccount: recipientAccount,
      transactionId: transactionId,
      occurredAt: occurredAt ?? DateTime.now(),
      failureReason: failureReason,
      errorTitleKey: errorTitleKey,
      errorBodyKey: errorBodyKey,
    );
  }

  /// Browse a recent / history transfer row on the Transfer Detail page.
  factory TransferResult.fromActivity({
    required int amountPoints,
    required String recipientAccount,
    required String transactionId,
    required DateTime occurredAt,
  }) {
    return TransferResult(
      status: TransferTxnStatus.success,
      amountPoints: amountPoints,
      recipientAccount: recipientAccount,
      transactionId: transactionId,
      occurredAt: occurredAt,
    );
  }
}
