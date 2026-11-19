class BudgetModel {
  const BudgetModel({
    this.id,
    this.category,
    required this.limitAmount,
    required this.period,
    required this.createdAt,
  });

  static const String weeklyPeriod = 'weekly';
  static const String monthlyPeriod = 'monthly';

  final int? id;
  final String? category;
  final double limitAmount;
  final String period;
  final DateTime createdAt;

  bool get isOverall => category == null;

  factory BudgetModel.fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map['id'] as int?,
      category: map['category'] as String?,
      limitAmount: (map['limit_amount'] as num).toDouble(),
      period: map['period'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'limit_amount': limitAmount,
      'period': period,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
