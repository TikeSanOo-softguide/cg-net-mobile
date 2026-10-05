/// Package purchase transaction result (never includes password).
enum PackageBuyTxnStatus { success, failure }

class PackageBuyResult {
  const PackageBuyResult({
    required this.status,
    required this.packageId,
    required this.packageTitle,
    required this.pricePoints,
    required this.autoRenew,
    required this.transactionId,
    required this.occurredAt,
    this.speedMbps,
    this.errorTitleKey,
    this.errorBodyKey,
    this.errorTitle,
    this.errorBody,
  });

  final PackageBuyTxnStatus status;
  final String packageId;
  final String packageTitle;
  final int pricePoints;
  final bool autoRenew;
  final String transactionId;
  final DateTime occurredAt;
  final String? speedMbps;
  final String? errorTitleKey;
  final String? errorBodyKey;
  final String? errorTitle;
  final String? errorBody;

  factory PackageBuyResult.success({
    required String packageId,
    required String packageTitle,
    required int pricePoints,
    required bool autoRenew,
    required String transactionId,
    String? speedMbps,
    DateTime? occurredAt,
  }) {
    return PackageBuyResult(
      status: PackageBuyTxnStatus.success,
      packageId: packageId,
      packageTitle: packageTitle,
      pricePoints: pricePoints,
      autoRenew: autoRenew,
      transactionId: transactionId,
      speedMbps: speedMbps,
      occurredAt: occurredAt ?? DateTime.now(),
    );
  }

  factory PackageBuyResult.failure({
    required String packageId,
    required String packageTitle,
    required int pricePoints,
    required bool autoRenew,
    required String transactionId,
    String? speedMbps,
    DateTime? occurredAt,
    String? errorTitleKey,
    String? errorBodyKey,
    String? errorTitle,
    String? errorBody,
  }) {
    return PackageBuyResult(
      status: PackageBuyTxnStatus.failure,
      packageId: packageId,
      packageTitle: packageTitle,
      pricePoints: pricePoints,
      autoRenew: autoRenew,
      transactionId: transactionId,
      speedMbps: speedMbps,
      occurredAt: occurredAt ?? DateTime.now(),
      errorTitleKey: errorTitleKey,
      errorBodyKey: errorBodyKey,
      errorTitle: errorTitle,
      errorBody: errorBody,
    );
  }

  /// Browse an activity list package row on the purchase detail page.
  factory PackageBuyResult.fromActivity({
    required String packageId,
    required String packageTitle,
    required int pricePoints,
    required String transactionId,
    required DateTime occurredAt,
    required bool success,
    String speedMbps = '20',
    bool autoRenew = true,
  }) {
    if (success) {
      return PackageBuyResult.success(
        packageId: packageId,
        packageTitle: packageTitle,
        pricePoints: pricePoints,
        autoRenew: autoRenew,
        transactionId: transactionId,
        speedMbps: speedMbps,
        occurredAt: occurredAt,
      );
    }
    return PackageBuyResult.failure(
      packageId: packageId,
      packageTitle: packageTitle,
      pricePoints: pricePoints,
      autoRenew: autoRenew,
      transactionId: transactionId,
      speedMbps: speedMbps,
      occurredAt: occurredAt,
      errorTitleKey: 'package.result_failure_title',
      errorBodyKey: 'package.result_failure_body',
    );
  }
}
