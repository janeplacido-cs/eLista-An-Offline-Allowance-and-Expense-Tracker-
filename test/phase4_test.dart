import 'package:elista/models/transaction_model.dart';
import 'package:elista/models/weekly_spending_summary.dart';
import 'package:elista/theme/app_theme.dart';
import 'package:elista/widgets/allowance_period_card.dart';
import 'package:elista/widgets/weekly_spending_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transaction map round-trips the optional allowance end date', () {
    final endDate = DateTime(2026, 12, 1);
    final transaction = TransactionModel.create(
      type: TransactionModel.allowanceType,
      amount: 800,
      category: 'Allowance',
      date: DateTime(2026, 11, 19),
      periodEndDate: endDate,
    );

    expect(
      TransactionModel.fromMap(transaction.toMap()).periodEndDate,
      endDate,
    );
    expect(
      TransactionModel.fromMap(
        Map<String, Object?>.of(transaction.toMap())..remove('period_end_date'),
      ).periodEndDate,
      isNull,
    );
  });

  testWidgets('allowance period counts today and labels the final day', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AllowancePeriodCard(
            startDate: today,
            endDate: today,
            remainingBalance: 350,
            todayExpenses: 20,
            onAddAllowance: () {},
            onExtendPeriod: () {},
          ),
        ),
      ),
    );

    expect(find.text('Last day'), findsOneWidget);
    expect(find.text('Safe to spend today: ₱350.00'), findsOneWidget);
    expect(find.text('On track'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      1,
    );
  });

  testWidgets('allowance period handles zero balance and ended period', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AllowancePeriodCard(
            startDate: today,
            endDate: today,
            remainingBalance: 0,
            todayExpenses: 1,
            onAddAllowance: () {},
            onExtendPeriod: () {},
          ),
        ),
      ),
    );

    expect(find.text('Safe to spend today: ₱0.00'), findsOneWidget);
    expect(find.text('Over budget'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AllowancePeriodCard(
            startDate: today.subtract(const Duration(days: 7)),
            endDate: today.subtract(const Duration(days: 1)),
            remainingBalance: 100,
            todayExpenses: 0,
            onAddAllowance: () {},
            onExtendPeriod: () {},
          ),
        ),
      ),
    );

    expect(find.text('Allowance period ended'), findsOneWidget);
    expect(find.text('Add new allowance'), findsOneWidget);
    expect(find.text('Extend period'), findsOneWidget);
  });

  test(
    'weekly summary includes expenses in this week only and resolves ties',
    () {
      final now = DateTime(2024, 6, 12, 12);
      final summary = WeeklySpendingSummary.fromTransactions([
        _transaction(TransactionModel.expenseType, 100, DateTime(2024, 6, 9)),
        _transaction(TransactionModel.expenseType, 12, DateTime(2024, 6, 10)),
        _transaction(TransactionModel.expenseType, 25, DateTime(2024, 6, 11)),
        _transaction(TransactionModel.expenseType, 25, DateTime(2024, 6, 15)),
        _transaction(TransactionModel.expenseType, 8, DateTime(2024, 6, 16)),
        _transaction(TransactionModel.expenseType, 500, DateTime(2024, 6, 17)),
        _transaction(
          TransactionModel.allowanceType,
          300,
          DateTime(2024, 6, 12),
        ),
      ], now: now);

      expect(summary.dailySpending, [12, 25, 0, 0, 0, 25, 8]);
      expect(summary.totalSpending, 70);
      expect(summary.highestSpendingDayIndex, 1);
      expect(summary.highestSpendingDate, DateTime(2024, 6, 11));
      expect(summary.highestDailySpending, 25);
    },
  );

  test('weekly summary represents an empty week without a highest day', () {
    final summary = WeeklySpendingSummary.fromTransactions([
      _transaction(TransactionModel.allowanceType, 100, DateTime(2024, 6, 12)),
    ], now: DateTime(2024, 6, 12));

    expect(summary.dailySpending, everyElement(0));
    expect(summary.totalSpending, 0);
    expect(summary.highestSpendingDate, isNull);
  });

  testWidgets('weekly bar chart displays all seven day labels', (tester) async {
    final summary = WeeklySpendingSummary.fromTransactions([
      _transaction(TransactionModel.expenseType, 25, DateTime(2024, 6, 11)),
    ], now: DateTime(2024, 6, 12));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: WeeklySpendingChart(summary: summary)),
      ),
    );
    await tester.pumpAndSettle();

    for (final day in ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']) {
      expect(find.text(day), findsOneWidget);
    }
  });
}

TransactionModel _transaction(String type, double amount, DateTime date) {
  return TransactionModel.create(
    type: type,
    amount: amount,
    category: type == TransactionModel.expenseType ? 'Food' : 'Allowance',
    date: date,
  );
}
