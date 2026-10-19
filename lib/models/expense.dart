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
