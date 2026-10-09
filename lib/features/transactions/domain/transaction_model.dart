enum TransactionType { expense, income }

enum TransactionSource { text, voice, receipt }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final String paymentMethod;
  final DateTime date;
  final TransactionSource source;
  final String? notes;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.paymentMethod,
    required this.date,
    required this.source,
    this.notes,
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    String? paymentMethod,
    DateTime? date,
    TransactionSource? source,
    String? notes,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      source: source ?? this.source,
      notes: notes ?? this.notes,
    );
  }
}
