class Transaction {
  final String id;
  final String postingDate;
  final double amount;
  final String type;
  final String category;
  final String category_name;
  final String note;

  const Transaction({
    required this.id,
    required this.postingDate,
    required this.amount,
    required this.type,
    required this.category,
    required this.category_name,
    required this.note,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final amountRaw = json['amount'];
    final parsedAmount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '0') ?? 0;

    return Transaction(
      id: json['id']?.toString() ?? '',
      postingDate: json['postingDate']?.toString() ?? '',
      amount: parsedAmount,
      type: json['type']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      category_name: json['category_name']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'postingDate': postingDate,
      'amount': amount,
      'type': type,
      'category': category,
      'category_name': category_name,
      'note': note,
    };
  }

  bool get isIncome {
    final normalized = type.trim().toLowerCase();
    switch (normalized) {
      case 'income':
      case 'in':
      case 'credit':
      case 'receipt':
      case 'received':
        return true;
      case 'expense':
      case 'out':
      case 'debit':
      case 'payment':
        return false;
      default:
        return false;
    }
  }

  String get title => category_name.isNotEmpty ? category_name : 'Transaction';

  DateTime? get postingDateValue => DateTime.tryParse(postingDate);
}
