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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category': category,
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(),
      'source': source.name,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map, [String? id]) {
    return TransactionModel(
      id: id ?? map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: (map['type'] == 'income')
          ? TransactionType.income
          : TransactionType.expense,
      category: map['category'] as String? ?? 'Lainnya',
      paymentMethod: map['paymentMethod'] as String? ?? 'Tunai',
      date: map['date'] != null
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      source: TransactionSource.values.firstWhere(
        (s) => s.name == map['source'],
        orElse: () => TransactionSource.text,
      ),
      notes: map['notes'] as String?,
    );
  }
}
