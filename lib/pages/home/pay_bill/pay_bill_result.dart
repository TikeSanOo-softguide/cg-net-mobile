enum PayBillTxnStatus { success, failure, pending }

class PayBillResult {
  const PayBillResult({
    required this.status,
    required this.amountPoints,
    required this.account,
    required this.serviceType,
    required this.productLabel,
    required this.speed,
    required this.transactionId,
    this.occurredAt,
    this.errorTitleKey,
    this.errorBodyKey,
    this.errorTitle,
    this.errorBody,
  });

  final PayBillTxnStatus status;
  final int amountPoints;
  final String account;
  final String serviceType;
  final String productLabel;
  final String speed;
  final String transactionId;
  final DateTime? occurredAt;
  final String? errorTitleKey;
  final String? errorBodyKey;
  final String? errorTitle;
  final String? errorBody;

  factory PayBillResult.success({
    required int amountPoints,
    required String account,
    required String serviceType,
    required String productLabel,
    required String speed,
    required String transactionId,
    DateTime? occurredAt,
  }) {
    return PayBillResult(
      status: PayBillTxnStatus.success,
      amountPoints: amountPoints,
      account: account,
      serviceType: serviceType,
      productLabel: productLabel,
      speed: speed,
      transactionId: transactionId,
      occurredAt: occurredAt,
    );
  }

  factory PayBillResult.pending({
    required int amountPoints,
    required String account,
    required String serviceType,
    required String productLabel,
    required String speed,
    required String transactionId,
    DateTime? occurredAt,
  }) {
    return PayBillResult(
      status: PayBillTxnStatus.pending,
      amountPoints: amountPoints,
      account: account,
      serviceType: serviceType,
      productLabel: productLabel,
      speed: speed,
      transactionId: transactionId,
      occurredAt: occurredAt,
    );
  }

  factory PayBillResult.failure({
    required int amountPoints,
    required String account,
    required String serviceType,
    required String productLabel,
    required String speed,
    required String transactionId,
    DateTime? occurredAt,
    String? errorTitleKey,
    String? errorBodyKey,
    String? errorTitle,
    String? errorBody,
  }) {
    return PayBillResult(
      status: PayBillTxnStatus.failure,
      amountPoints: amountPoints,
      account: account,
      serviceType: serviceType,
      productLabel: productLabel,
      speed: speed,
      transactionId: transactionId,
      occurredAt: occurredAt,
      errorTitleKey: errorTitleKey,
      errorBodyKey: errorBodyKey,
      errorTitle: errorTitle,
      errorBody: errorBody,
    );
  }

  static bool isPendingStatus(String status) {
    final value = status.trim().toLowerCase();
    return value.contains('process') ||
        value == 'review' ||
        value == 'pending';
  }
}
