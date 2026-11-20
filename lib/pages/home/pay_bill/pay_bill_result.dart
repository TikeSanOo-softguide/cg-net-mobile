enum PayBillTxnStatus { success, pending }

class PayBillResult {
  PayBillResult({
    required this.status,
    required this.amountPoints,
    required this.account,
    required this.serviceType,
    required this.productLabel,
    required this.speed,
    required this.transactionId,
    this.occurredAt,
    this.accountName = '',
    String? remark,
  }) : remark = remark ?? '';

  final PayBillTxnStatus status;
  final int amountPoints;
  final String account;
  final String serviceType;
  final String productLabel;
  final String speed;
  final String transactionId;
  final DateTime? occurredAt;
  final String accountName;
  final String remark;

  factory PayBillResult.success({
    required int amountPoints,
    required String account,
    required String serviceType,
    required String productLabel,
    required String speed,
    required String transactionId,
    DateTime? occurredAt,
    String accountName = '',
    String remark = '',
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
      accountName: accountName,
      remark: remark,
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
    String accountName = '',
    String remark = '',
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
      accountName: accountName,
      remark: remark,
    );
  }

  static bool isPendingStatus(String status) {
    final value = status.trim().toLowerCase();
    return value.contains('process') ||
        value == 'review' ||
        value == 'pending';
  }
}
