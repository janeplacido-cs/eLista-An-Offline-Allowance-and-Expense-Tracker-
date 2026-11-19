import 'package:elista/models/budget_model.dart';
import 'package:elista/models/transaction_model.dart';
import 'package:elista/services/insights_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('week over week compares Monday through Sunday boundaries', () {
    final insights = _generate(
      now: DateTime(2024, 6, 12),
      transactions: [
        _expense(40, DateTime(2024, 6, 3)),
        _expense(20, DateTime(2024, 6, 9)),
        _expense(20, DateTime(2024, 6, 10)),
        _expense(10, DateTime(2024, 6, 16)),
        _expense(1000, DateTime(2024, 6, 17)),
      ],
    );

    final insight = _byType(insights, InsightType.weekOverWeek);
    expect(insight.message, 'You spent 50% less than last week.');
    expect(insight.severity, InsightSeverity.good);
  });

  test('week over week requires spending in both weeks', () {
    final noLastWeekSpending = _generate(
      now: DateTime(2024, 6, 12),
      transactions: [_expense(10, DateTime(2024, 6, 10))],
    );
    final noCurrentWeekSpending = _generate(
      now: DateTime(2024, 6, 12),
      transactions: [_expense(10, DateTime(2024, 6, 3))],
    );

    expect(
      noLastWeekSpending.where(
        (insight) => insight.type == InsightType.weekOverWeek,
      ),
      isEmpty,
    );
    expect(
      noCurrentWeekSpending.where(
        (insight) => insight.type == InsightType.weekOverWeek,
      ),
      isEmpty,
    );
  });

  test(
    'top category reports its share of current allowance-period expenses',
    () {
      final insights = _generate(
        now: DateTime(2024, 6, 12),
        allowanceEnd: DateTime(2024, 6, 30),
        transactions: [
          _allowance(500, DateTime(2024, 6, 1), id: 1),
          _expense(60, DateTime(2024, 6, 10), category: 'Food'),
          _expense(40, DateTime(2024, 6, 11), category: 'Transport'),
        ],
      );

      final insight = _byType(insights, InsightType.topCategory);
      expect(
        insight.message,
        'Food is your top spending, 60% of your expenses.',
      );
    },
  );

  test('run-out projection reports days early and a sustainable pace', () {
    final transactions = [
      _allowance(300, DateTime(2026, 1, 1), id: 1),
      _expense(60, DateTime(2026, 1, 3)),
    ];
    final shortfall = _generate(
      now: DateTime(2026, 1, 3),
      allowanceEnd: DateTime(2026, 1, 20),
      transactions: transactions,
    );
    final onTrack = _generate(
      now: DateTime(2026, 1, 3),
      allowanceEnd: DateTime(2026, 1, 10),
      transactions: transactions,
    );

    expect(
      _byType(shortfall, InsightType.runOutPrediction).message,
      'At this pace, your allowance may run out 6 days before it ends.',
    );
    expect(
      _byType(onTrack, InsightType.runOutPrediction).severity,
      InsightSeverity.good,
    );
    expect(
      _byType(onTrack, InsightType.runOutPrediction).message,
      'At this pace, your allowance should last through the end date.',
    );
  });

  test('run-out projection handles an end date today or already passed', () {
    final transactions = [
      _allowance(100, DateTime(2026, 1, 1), id: 1),
      _expense(100, DateTime(2026, 1, 3)),
    ];
    final endsToday = _generate(
      now: DateTime(2026, 1, 3),
      allowanceEnd: DateTime(2026, 1, 3),
      transactions: transactions,
    );
    final alreadyEnded = _generate(
      now: DateTime(2026, 1, 3),
      allowanceEnd: DateTime(2026, 1, 2),
      transactions: transactions,
    );

    expect(
      _byType(endsToday, InsightType.runOutPrediction).message,
      'At this pace, your remaining allowance may run out today.',
    );
    expect(
      _byType(alreadyEnded, InsightType.runOutPrediction).message,
      'Your allowance period ended 1 day ago.',
    );
  });

  test('run-out projection requires two elapsed days and an expense', () {
    final endDate = DateTime(2026, 1, 20);
    final oneDay = _generate(
      now: DateTime(2026, 1, 1),
      allowanceEnd: endDate,
      transactions: [_allowance(300, DateTime(2026, 1, 1), id: 1)],
    );
    final noExpenses = _generate(
      now: DateTime(2026, 1, 3),
      allowanceEnd: endDate,
      transactions: [_allowance(300, DateTime(2026, 1, 1), id: 1)],
    );

    expect(
      oneDay.where((insight) => insight.type == InsightType.runOutPrediction),
      isEmpty,
    );
    expect(
      noExpenses.where(
        (insight) => insight.type == InsightType.runOutPrediction,
      ),
      isEmpty,
    );
  });

  test('budget insights include 80 percent and over-limit budgets', () {
    final insights = _generate(
      now: DateTime(2024, 6, 12),
      transactions: [
        _expense(80, DateTime(2024, 6, 11), category: 'Food'),
        _expense(120, DateTime(2024, 6, 11), category: 'Transport'),
      ],
      budgets: [
        _budget(100, category: 'Food'),
        _budget(100, category: 'Transport'),
        _budget(100, category: null, period: BudgetModel.monthlyPeriod),
        _budget(0, category: 'Other'),
      ],
    );

    final warnings = insights
        .where((insight) => insight.type == InsightType.budgetWarning)
        .toList();
    expect(warnings, hasLength(3));
    expect(
      warnings.map((insight) => insight.severity),
      everyElement(InsightSeverity.warning),
    );
    expect(insights.first.severity, InsightSeverity.warning);
    expect(
      warnings.map((insight) => insight.message),
      contains('Food budget is at 80% of its limit.'),
    );
    expect(
      warnings.map((insight) => insight.message),
      contains('Transport budget is at 120% of its limit.'),
    );
  });

  test(
    'no-spend days, daily average, and highest day are calculated this week',
    () {
      final insights = _generate(
        now: DateTime(2024, 6, 12),
        transactions: [
          _allowance(500, DateTime(2024, 6, 10), id: 1),
          _expense(10, DateTime(2024, 6, 10)),
          _expense(50, DateTime(2024, 6, 12)),
          _expense(500, DateTime(2024, 6, 17)),
        ],
      );

      expect(
        _byType(insights, InsightType.noSpendDays).message,
        '1 no-spend day this week. Nice!',
      );
      expect(
        _byType(insights, InsightType.averageDailySpending).message,
        'Average spending is ₱20.00 per day this week.',
      );
      expect(
        _byType(insights, InsightType.highestSpendingDay).message,
        'Wednesday was highest at ₱50.00.',
      );
    },
  );

  test('zero spending and zero-limit budgets do not divide by zero', () {
    final insights = _generate(
      now: DateTime(2024, 6, 12),
      budgets: [_budget(0)],
    );

    expect(insights, isEmpty);
  });

  test(
    'an allowance without any expense history keeps the empty state clear',
    () {
      final insights = _generate(
        now: DateTime(2024, 6, 12),
        transactions: [_allowance(500, DateTime(2024, 6, 10), id: 1)],
      );

      expect(insights, isEmpty);
    },
  );

  test('insights sort warnings before good news and information', () {
    final insights = _generate(
      now: DateTime(2026, 1, 3),
      allowanceEnd: DateTime(2026, 1, 20),
      transactions: [
        _allowance(300, DateTime(2026, 1, 1), id: 1),
        _expense(60, DateTime(2026, 1, 3), category: 'Food'),
        _expense(40, DateTime(2025, 12, 31), category: 'Food'),
      ],
      budgets: [_budget(50, category: 'Food')],
    );

    final ranks = insights.map((insight) {
      return switch (insight.severity) {
        InsightSeverity.warning => 0,
        InsightSeverity.good => 1,
        InsightSeverity.info => 2,
      };
    }).toList();
    expect(ranks, orderedEquals([...ranks]..sort()));
  });
}

List<Insight> _generate({
  required DateTime now,
  List<TransactionModel> transactions = const [],
  List<BudgetModel> budgets = const [],
  DateTime? allowanceEnd,
}) {
  return InsightsService.generateInsights(
    transactions: transactions,
    budgets: budgets,
    allowancePeriodEndDate: allowanceEnd,
    now: now,
  );
}

Insight _byType(List<Insight> insights, InsightType type) =>
    insights.singleWhere((insight) => insight.type == type);

TransactionModel _allowance(double amount, DateTime date, {required int id}) {
  return TransactionModel.create(
    id: id,
    type: TransactionModel.allowanceType,
    amount: amount,
    category: 'Weekly allowance',
    date: date,
    createdAt: date,
  );
}

TransactionModel _expense(
  double amount,
  DateTime date, {
  String category = 'Food',
}) {
  return TransactionModel.create(
    type: TransactionModel.expenseType,
    amount: amount,
    category: category,
    date: date,
    createdAt: date,
  );
}

BudgetModel _budget(
  double limit, {
  String? category,
  String period = BudgetModel.weeklyPeriod,
}) {
  return BudgetModel(
    category: category,
    limitAmount: limit,
    period: period,
    createdAt: DateTime(2024, 6, 1),
  );
}
