import '../../core/network/message_codes.dart';

class HistoryModel {
  const HistoryModel({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.transactionNo,
    required this.createdAt,
    this.status = '',
    this.direction = '',
    this.titleCode = '',
    this.descriptionCode = '',
    this.account = '',
    this.serviceType = '',
    this.orderNo = '',
    this.remark = '',
    this.productName = '',
    this.productSpeed = '',
  });

  final String id;
  final String type;
  final String description;
  final num? amount;
  final String? transactionNo;
  final DateTime createdAt;
  final String status;
  final String direction;
  final String titleCode;
  final String descriptionCode;
  final String account;
  final String serviceType;
  final String orderNo;
  final String remark;
  final String productName;
  final String productSpeed;

  bool get isCredit => direction.toLowerCase() == 'credit';
  bool get isDebit => direction.toLowerCase() == 'debit';

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    final package = json['package'];
    final packageMap = package is Map ? package : const {};
    final packageName = packageMap['product_name']?.toString().trim() ?? '';
    final productSpeed = packageMap['product_speed']?.toString().trim() ?? '';
    final remark = json['remark']?.toString().trim() ?? '';
    final note = (remark.isNotEmpty
                ? remark
                : (json['note'] ?? json['description']))
            ?.toString()
            .trim() ??
        '';
    final isBillHistory = json['order_no'] != null ||
        json['account'] != null ||
        json['service_type'] != null ||
        json['package'] != null;
    final type = json['type']?.toString().trim() ?? '';
    final status = json['status']?.toString() ?? '';
    final statusCode = _messageCodeForStatus(status);
    final titleCode = json['title_code']?.toString().trim() ?? '';
    final descriptionCode = json['description_code']?.toString().trim() ?? '';

    return HistoryModel(
      id: json['id']?.toString() ?? '',
      type: type.isNotEmpty ? type : (isBillHistory ? 'ftth_bill' : ''),
      description: note.isNotEmpty ? note : packageName,
      amount: _toNum(json['amount']),
      transactionNo: json['transaction_no']?.toString(),
      createdAt: _parseTime(
        json['confirmed_at'] ?? json['posted_at'] ?? json['created_at'],
      ),
      status: status,
      direction: json['direction']?.toString().trim().isNotEmpty == true
          ? json['direction'].toString()
          : (isBillHistory ? 'debit' : ''),
      titleCode: titleCode.isNotEmpty ? titleCode : (statusCode ?? ''),
      descriptionCode:
          descriptionCode.isNotEmpty ? descriptionCode : (statusCode ?? ''),
      account: json['account']?.toString() ?? '',
      serviceType: json['service_type']?.toString() ?? '',
      orderNo: json['order_no']?.toString() ?? '',
      remark: remark,
      productName: packageName,
      productSpeed: productSpeed,
    );
  }

  static String? _messageCodeForStatus(String status) {
    return switch (status.toLowerCase()) {
      'completed' => MessageCodes.ftthPaid,
      'pending' || 'processing' || 'review' => MessageCodes.ftthProcessing,
      _ => null,
    };
  }

  static num? _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static DateTime _parseTime(Object? raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    return DateTime.tryParse(text.replaceFirst(' ', 'T')) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
