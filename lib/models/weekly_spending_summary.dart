import 'package:flutter/foundation.dart';

import 'transaction_model.dart';

@immutable
class WeeklySpendingSummary {
  WeeklySpendingSummary._({
    required this.weekStart,
    required List<double> dailySpending,
  }) : dailySpending = List.unmodifiable(dailySpending);

  final DateTime weekStart;
  final List<double> dailySpending;

  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  double get totalSpending =>
      dailySpending.fold(0, (total, amount) => total + amount);

  int? get highestSpendingDayIndex {
    if (totalSpending == 0) return null;
    var highestIndex = 0;
    for (var index = 1; index < dailySpending.length; index++) {
      if (dailySpending[index] > dailySpending[highestIndex]) {
        highestIndex = index;
      }
    }
    return highestIndex;
  }

  DateTime? get highestSpendingDate {
    final index = highestSpendingDayIndex;
    return index == null ? null : weekStart.add(Duration(days: index));
  }

  double? get highestDailySpending {
    final index = highestSpendingDayIndex;
    return index == null ? null : dailySpending[index];
  }

  factory WeeklySpendingSummary.fromTransactions(
    List<TransactionModel> transactions, {
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final start = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final end = start.add(const Duration(days: 7));
    final dailySpending = List<double>.filled(7, 0);

    for (final transaction in transactions) {
      if (transaction.type != TransactionModel.expenseType ||
          transaction.date.isBefore(start) ||
          !transaction.date.isBefore(end)) {
        continue;
      }
      dailySpending[transaction.date.weekday - DateTime.monday] +=
          transaction.amount;
    }

    return WeeklySpendingSummary._(
      weekStart: start,
      dailySpending: dailySpending,
    );
  }
}
