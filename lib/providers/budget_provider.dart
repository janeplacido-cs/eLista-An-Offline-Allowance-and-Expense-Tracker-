import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class BudgetProvider extends ChangeNotifier {
  BudgetProvider({DbHelper? database})
    : _database = database ?? DbHelper.instance;

  final DbHelper _database;
  List<BudgetModel> _budgets = const [];
  Object? _loadError;
  bool _isLoading = false;

  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  Object? get loadError => _loadError;
  bool get isLoading => _isLoading;

  Future<void> loadBudgets() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _budgets = await _database.getBudgets();
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveBudget(BudgetModel budget) async {
    final matchingBudget = _budgets.where(
      (item) =>
          item.category == budget.category &&
          item.period == budget.period &&
          item.id != budget.id,
    );
    final duplicate = matchingBudget.isEmpty ? null : matchingBudget.first;

    if (duplicate != null) {
      await _database.updateBudget(
        BudgetModel(
          id: duplicate.id,
          category: budget.category,
          limitAmount: budget.limitAmount,
          period: budget.period,
          createdAt: duplicate.createdAt,
        ),
      );
    } else if (budget.id == null) {
      await _database.insertBudget(budget);
    } else {
      await _database.updateBudget(budget);
    }

    await loadBudgets();
    _throwIfRefreshFailed('saved');
  }

  Future<void> deleteBudget(int id) async {
    await _database.deleteBudget(id);
    await loadBudgets();
    _throwIfRefreshFailed('deleted');
  }

  void _throwIfRefreshFailed(String action) {
    if (_loadError != null) {
      throw StateError('Budget was $action, but the list could not refresh.');
    }
  }

  double spentFor(
    BudgetModel budget,
    List<TransactionModel> transactions, {
    DateTime? now,
  }) {
    final referenceDate = now ?? DateTime.now();
    final range = _periodRange(budget.period, referenceDate);
    return transactions
        .where(
          (transaction) =>
              transaction.type == TransactionModel.expenseType &&
              (budget.category == null ||
                  transaction.category == budget.category) &&
              !transaction.date.isBefore(range.start) &&
              transaction.date.isBefore(range.end),
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  ({DateTime start, DateTime end}) _periodRange(
    String period,
    DateTime referenceDate,
  ) {
    final date = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    if (period == BudgetModel.weeklyPeriod) {
      final start = date.subtract(
        Duration(days: date.weekday - DateTime.monday),
      );
      return (start: start, end: start.add(const Duration(days: 7)));
    }
    if (period == BudgetModel.monthlyPeriod) {
      final start = DateTime(date.year, date.month);
      return (start: start, end: DateTime(date.year, date.month + 1));
    }
    throw ArgumentError.value(period, 'period', 'Unsupported budget period.');
  }
}
