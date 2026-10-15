class HistoryModel {
  const HistoryModel({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.transactionNo,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String description;
  final num? amount;
  final String? transactionNo;
  final DateTime createdAt;

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      amount: _toNum(json['amount']),
      transactionNo: json['transaction_no']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  static num? _toNum(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }
}
