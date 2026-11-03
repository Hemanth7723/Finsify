class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.timestamp,
    this.note = '',
  });

  final int id;
  final String title;
  final double amount;
  final String category;
  final DateTime timestamp;
  final String note;

  Expense copyWith({
    int? id,
    String? title,
    double? amount,
    String? category,
    DateTime? timestamp,
    String? note,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      note: (map['note'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          amount == other.amount &&
          category == other.category &&
          timestamp == other.timestamp &&
          note == other.note;

  @override
  int get hashCode => Object.hash(id, title, amount, category, timestamp, note);
}

const expenseCategories = <String>[
  'Food',
  'Transport',
  'Entertainment',
  'Shopping',
  'Health',
  'Utilities',
  'Miscellaneous',
];
