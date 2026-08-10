/// Represents a single Cash In or Cash Out entry.
/// Converts cleanly to/from the SQLite Map format used by DatabaseHelper.
class Expense {
  final int? id;
  final String userId;
  final String type; // 'cash_in' or 'cash_out'
  final double amount;
  final String description;
  final String category;
  final String paymentMode;
  final String? contactName;
  final String date; // 'YYYY-MM-DD'

  Expense({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.category,
    required this.paymentMode,
    this.contactName,
    required this.date,
  });

  bool get isCashIn => type == 'cash_in';
  bool get isCashOut => type == 'cash_out';

  /// Signed amount: positive for Cash In, negative for Cash Out.
  /// Useful for running-balance calculations.
  double get signedAmount => isCashIn ? amount : -amount;

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'cash_out',
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      paymentMode: map['paymentMode'] as String? ?? 'Cash',
      contactName: map['contactName'] as String?,
      date: map['date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'category': category,
      'paymentMode': paymentMode,
      'contactName': contactName,
      'date': date,
    };
  }
}