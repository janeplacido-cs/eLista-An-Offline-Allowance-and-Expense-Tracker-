class TransactionModel {
  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.createdAt,
    this.periodEndDate,
  });

  static const String allowanceType = 'allowance';
  static const String expenseType = 'expense';
  static const List<String> expenseCategories = [
    'Food',
    'Transport',
    'School',
    'Bills',
    'Shopping',
    'Health',
    'Entertainment',
    'Other',
  ];

  final int? id;
  final String type;
  final double amount;
  final String category;
  final String? note;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? periodEndDate;

  bool get isExpense => type == expenseType;

  factory TransactionModel.create({
    int? id,
    required String type,
    required double amount,
    required String category,
    String? note,
    required DateTime date,
    DateTime? createdAt,
    DateTime? periodEndDate,
  }) {
    return TransactionModel(
      id: id,
      type: type,
      amount: amount,
      category: category,
      note: note,
      date: date,
      createdAt: createdAt ?? DateTime.now(),
      periodEndDate: periodEndDate,
    );
  }

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    return TransactionModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String? ?? 'Other',
      note: map['note'] as String?,
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      periodEndDate: map['period_end_date'] == null
          ? null
          : DateTime.parse(map['period_end_date'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'period_end_date': periodEndDate?.toIso8601String(),
    };
  }

  TransactionModel copyWith({
    int? id,
    DateTime? periodEndDate,
    bool clearPeriodEndDate = false,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type,
      amount: amount,
      category: category,
      note: note,
      date: date,
      createdAt: createdAt,
      periodEndDate: clearPeriodEndDate
          ? null
          : periodEndDate ?? this.periodEndDate,
    );
  }
}
