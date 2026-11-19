import 'package:intl/intl.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../models/weekly_spending_summary.dart';

enum InsightSeverity { warning, good, info }

enum InsightType {
  weekOverWeek,
  topCategory,
  runOutPrediction,
  budgetWarning,
  noSpendDays,
  averageDailySpending,
  highestSpendingDay,
}

enum InsightIcon {
  trendingDown,
  category,
  calendar,
  budget,
  savings,
  average,
  highest,
}

class Insight {
  const Insight({
    required this.type,
    required this.title,
    required this.message,
    required this.severity,
    this.icon,
  });

  final InsightType type;
  final String title;
  final String message;
  final InsightSeverity severity;
  final InsightIcon? icon;
}

class InsightsService {
  const InsightsService._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );
  static final DateFormat _weekday = DateFormat('EEEE');

  static List<Insight> generateInsights({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required DateTime? allowancePeriodEndDate,
    required DateTime now,
  }) {
    final today = _dateOnly(now);
    final weekSummary = WeeklySpendingSummary.fromTransactions(
      transactions,
      now: today,
    );
    final weekStart = weekSummary.weekStart;
    final previousWeekStart = weekStart.subtract(const Duration(days: 7));
    final elapsedWeekDays = today.difference(weekStart).inDays + 1;
    final currentWeekSpending = weekSummary.totalSpending;
    final previousWeekSpending = _totalExpenses(
      transactions,
      previousWeekStart,
      weekStart,
    );
    final currentWeekToDate = weekSummary.dailySpending
        .take(elapsedWeekDays)
        .fold<double>(0, (total, amount) => total + amount);
    final insights = <Insight>[];

    _addBudgetInsights(
      insights,
      transactions: transactions,
      budgets: budgets,
      today: today,
    );
    _addRunOutInsight(
      insights,
      transactions: transactions,
      allowancePeriodEndDate: allowancePeriodEndDate,
      today: today,
    );

    if (previousWeekSpending > 0 && currentWeekSpending > 0) {
      final changePercent =
          ((currentWeekSpending - previousWeekSpending) /
                  previousWeekSpending *
                  100)
              .round();
      if (changePercent < 0) {
        insights.add(
          Insight(
            type: InsightType.weekOverWeek,
            title: 'Spending is down',
            message: 'You spent ${changePercent.abs()}% less than last week.',
            severity: InsightSeverity.good,
            icon: InsightIcon.trendingDown,
          ),
        );
      } else if (changePercent > 0) {
        insights.add(
          Insight(
            type: InsightType.weekOverWeek,
            title: 'Weekly spending',
            message: 'Spending is up $changePercent% from last week.',
            severity: InsightSeverity.info,
            icon: InsightIcon.trendingDown,
          ),
        );
      } else {
        insights.add(
          const Insight(
            type: InsightType.weekOverWeek,
            title: 'Weekly spending',
            message: 'Your spending is about the same as last week.',
            severity: InsightSeverity.info,
            icon: InsightIcon.trendingDown,
          ),
        );
      }
    }

    _addTopCategoryInsight(
      insights,
      transactions: transactions,
      today: today,
      allowancePeriodEndDate: allowancePeriodEndDate,
    );

    final hasExpenseHistory = transactions.any(
      (transaction) => transaction.type == TransactionModel.expenseType,
    );
    if (hasExpenseHistory) {
      final noSpendDays = weekSummary.dailySpending
          .take(elapsedWeekDays)
          .where((amount) => amount == 0)
          .length;
      insights.add(
        Insight(
          type: InsightType.noSpendDays,
          title: 'No-spend days',
          message: noSpendDays == 0
              ? 'Spending has been recorded each day this week so far.'
              : '$noSpendDays no-spend ${noSpendDays == 1 ? 'day' : 'days'} '
                    'this week. Nice!',
          severity: noSpendDays == 0
              ? InsightSeverity.info
              : InsightSeverity.good,
          icon: InsightIcon.savings,
        ),
      );
    }

    if (currentWeekToDate > 0) {
      final average = currentWeekToDate / elapsedWeekDays;
      insights.add(
        Insight(
          type: InsightType.averageDailySpending,
          title: 'Daily average',
          message:
              'Average spending is ${_currency.format(average)} per day this week.',
          severity: InsightSeverity.info,
          icon: InsightIcon.average,
        ),
      );
    }

    final highestDate = weekSummary.highestSpendingDate;
    final highestAmount = weekSummary.highestDailySpending;
    if (highestDate != null && highestAmount != null) {
      insights.add(
        Insight(
          type: InsightType.highestSpendingDay,
          title: 'Highest spending day',
          message:
              '${_weekday.format(highestDate)} was highest at '
              '${_currency.format(highestAmount)}.',
          severity: InsightSeverity.info,
          icon: InsightIcon.highest,
        ),
      );
    }

    final ordered = insights.indexed.toList()
      ..sort((left, right) {
        final severityOrder = _severityRank(
          left.$2.severity,
        ).compareTo(_severityRank(right.$2.severity));
        return severityOrder != 0 ? severityOrder : left.$1.compareTo(right.$1);
      });
    return List<Insight>.unmodifiable(ordered.map((entry) => entry.$2));
  }

  static void _addBudgetInsights(
    List<Insight> insights, {
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    required DateTime today,
  }) {
    for (final budget in budgets) {
      if (budget.limitAmount <= 0) continue;
      final range = _budgetPeriodRange(budget.period, today);
      if (range == null) continue;
      final spent = transactions
          .where(
            (transaction) =>
                transaction.type == TransactionModel.expenseType &&
                (budget.category == null ||
                    transaction.category == budget.category) &&
                !transaction.date.isBefore(range.start) &&
                transaction.date.isBefore(range.end),
          )
          .fold<double>(0, (total, transaction) => total + transaction.amount);
      final percent = (spent / budget.limitAmount * 100).round();
      if (percent < 80) continue;

      final label = budget.category ?? 'Overall';
      final exceeded = spent >= budget.limitAmount;
      insights.add(
        Insight(
          type: InsightType.budgetWarning,
          title: exceeded ? '$label budget reached' : '$label budget nearby',
          message: '$label budget is at $percent% of its limit.',
          severity: InsightSeverity.warning,
          icon: InsightIcon.budget,
        ),
      );
    }
  }

  static void _addRunOutInsight(
    List<Insight> insights, {
    required List<TransactionModel> transactions,
    required DateTime? allowancePeriodEndDate,
    required DateTime today,
  }) {
    if (allowancePeriodEndDate == null) return;
    final endDate = _dateOnly(allowancePeriodEndDate);
    if (endDate.isBefore(today)) {
      final daysAgo = today.difference(endDate).inDays;
      insights.add(
        Insight(
          type: InsightType.runOutPrediction,
          title: 'Allowance period ended',
          message:
              'Your allowance period ended $daysAgo '
              '${daysAgo == 1 ? 'day' : 'days'} ago.',
          severity: InsightSeverity.warning,
          icon: InsightIcon.calendar,
        ),
      );
      return;
    }

    final allowance = _latestAllowance(transactions);
    if (allowance == null) return;
    final periodStart = _dateOnly(allowance.date);
    if (periodStart.isAfter(today)) return;
    final elapsedDays = today.difference(periodStart).inDays + 1;
    if (elapsedDays < 2) return;

    final expenses = transactions
        .where(
          (transaction) =>
              transaction.type == TransactionModel.expenseType &&
              !transaction.date.isBefore(periodStart) &&
              transaction.date.isBefore(today.add(const Duration(days: 1))),
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    if (expenses <= 0) return;

    final allowances = transactions
        .where(
          (transaction) =>
              transaction.type == TransactionModel.allowanceType &&
              !transaction.date.isBefore(periodStart) &&
              transaction.date.isBefore(today.add(const Duration(days: 1))),
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final averageDailySpending = expenses / elapsedDays;
    if (averageDailySpending <= 0) return;

    final remainingBalance = allowances - expenses;
    final daysBalanceLasts = remainingBalance <= 0
        ? 0
        : (remainingBalance / averageDailySpending).ceil();
    final daysUntilEnd = endDate.difference(today).inDays + 1;
    if (daysBalanceLasts < daysUntilEnd) {
      if (daysUntilEnd == 1) {
        insights.add(
          const Insight(
            type: InsightType.runOutPrediction,
            title: 'Allowance may run out today',
            message:
                'At this pace, your remaining allowance may run out today.',
            severity: InsightSeverity.warning,
            icon: InsightIcon.calendar,
          ),
        );
        return;
      }
      final daysEarly = daysUntilEnd - daysBalanceLasts;
      insights.add(
        Insight(
          type: InsightType.runOutPrediction,
          title: 'Allowance may run out early',
          message:
              'At this pace, your allowance may run out $daysEarly '
              '${daysEarly == 1 ? 'day' : 'days'} before it ends.',
          severity: InsightSeverity.warning,
          icon: InsightIcon.calendar,
        ),
      );
      return;
    }

    insights.add(
      const Insight(
        type: InsightType.runOutPrediction,
        title: 'Allowance is on track',
        message:
            'At this pace, your allowance should last through the end date.',
        severity: InsightSeverity.good,
        icon: InsightIcon.calendar,
      ),
    );
  }

  static void _addTopCategoryInsight(
    List<Insight> insights, {
    required List<TransactionModel> transactions,
    required DateTime today,
    required DateTime? allowancePeriodEndDate,
  }) {
    final allowance = _latestAllowance(transactions);
    if (allowance == null) return;
    final periodStart = _dateOnly(allowance.date);
    if (periodStart.isAfter(today)) return;

    var periodEnd = today.add(const Duration(days: 1));
    if (allowancePeriodEndDate != null) {
      final declaredEnd = _dateOnly(allowancePeriodEndDate);
      if (declaredEnd.isBefore(periodEnd)) {
        periodEnd = declaredEnd.add(const Duration(days: 1));
      }
    }
    final categorySpending = <String, double>{};
    var totalSpending = 0.0;
    for (final transaction in transactions) {
      if (transaction.type != TransactionModel.expenseType ||
          transaction.date.isBefore(periodStart) ||
          !transaction.date.isBefore(periodEnd)) {
        continue;
      }
      categorySpending.update(
        transaction.category,
        (total) => total + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
      totalSpending += transaction.amount;
    }
    if (totalSpending <= 0 || categorySpending.isEmpty) return;

    final topCategory = categorySpending.entries.toList()
      ..sort((left, right) {
        final amountOrder = right.value.compareTo(left.value);
        return amountOrder != 0
            ? amountOrder
            : left.key.toLowerCase().compareTo(right.key.toLowerCase());
      });
    final top = topCategory.first;
    final share = (top.value / totalSpending * 100).round();
    insights.add(
      Insight(
        type: InsightType.topCategory,
        title: 'Top spending category',
        message: '${top.key} is your top spending, $share% of your expenses.',
        severity: InsightSeverity.info,
        icon: InsightIcon.category,
      ),
    );
  }

  static TransactionModel? _latestAllowance(
    List<TransactionModel> transactions,
  ) {
    TransactionModel? latest;
    for (final transaction in transactions) {
      if (transaction.type != TransactionModel.allowanceType) continue;
      if (latest == null ||
          transaction.createdAt.isAfter(latest.createdAt) ||
          (transaction.createdAt.isAtSameMomentAs(latest.createdAt) &&
              (transaction.id ?? 0) > (latest.id ?? 0))) {
        latest = transaction;
      }
    }
    return latest;
  }

  static double _totalExpenses(
    List<TransactionModel> transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions
        .where(
          (transaction) =>
              transaction.type == TransactionModel.expenseType &&
              !transaction.date.isBefore(start) &&
              transaction.date.isBefore(end),
        )
        .fold<double>(0, (total, transaction) => total + transaction.amount);
  }

  static ({DateTime start, DateTime end})? _budgetPeriodRange(
    String period,
    DateTime today,
  ) {
    if (period == BudgetModel.weeklyPeriod) {
      final start = today.subtract(
        Duration(days: today.weekday - DateTime.monday),
      );
      return (start: start, end: start.add(const Duration(days: 7)));
    }
    if (period == BudgetModel.monthlyPeriod) {
      final start = DateTime(today.year, today.month);
      return (start: start, end: DateTime(today.year, today.month + 1));
    }
    return null;
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static int _severityRank(InsightSeverity severity) => switch (severity) {
    InsightSeverity.warning => 0,
    InsightSeverity.good => 1,
    InsightSeverity.info => 2,
  };
}
