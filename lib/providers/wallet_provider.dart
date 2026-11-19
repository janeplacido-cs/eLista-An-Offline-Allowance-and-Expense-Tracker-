import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/transaction_model.dart';

class WalletProvider extends ChangeNotifier {
  WalletProvider({DbHelper? database})
    : _database = database ?? DbHelper.instance;

  final DbHelper _database;
  List<TransactionModel> _transactions = const [];
  Object? _loadError;
  bool _isLoading = false;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  Object? get loadError => _loadError;
  bool get isLoading => _isLoading;

  double get totalAllowance => _sumForType(TransactionModel.allowanceType);
  double get totalExpenses => _sumForType(TransactionModel.expenseType);
  double get remainingBalance => totalAllowance - totalExpenses;
  TransactionModel? get currentAllowance => _transactions
      .where(
        (transaction) => transaction.type == TransactionModel.allowanceType,
      )
      .fold<TransactionModel?>(null, (latest, candidate) {
        if (latest == null ||
            candidate.createdAt.isAfter(latest.createdAt) ||
            (candidate.createdAt.isAtSameMomentAs(latest.createdAt) &&
                (candidate.id ?? 0) > (latest.id ?? 0))) {
          return candidate;
        }
        return latest;
      });

  DateTime? get allowancePeriodEndDate => currentAllowance?.periodEndDate;

  double get todayExpenses {
    final today = DateTime.now();
    return _transactions
        .where(
          (transaction) =>
              transaction.isExpense &&
              transaction.date.year == today.year &&
              transaction.date.month == today.month &&
              transaction.date.day == today.day,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  List<TransactionModel> get recentTransactions =>
      _transactions.take(5).toList(growable: false);

  double _sumForType(String type) {
    return _transactions
        .where((transaction) => transaction.type == type)
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _transactions = await _database.getTransactions();
    } catch (error) {
      _loadError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final id = await _database.insertTransaction(transaction);
    await loadTransactions();
    if (_loadError != null) {
      throw StateError(
        'Transaction was saved, but the wallet could not refresh.',
      );
    }
    if (!_transactions.any((item) => item.id == id)) {
      _transactions = [transaction.copyWith(id: id), ..._transactions];
      notifyListeners();
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    await _database.updateTransaction(transaction);
    await loadTransactions();
    if (_loadError != null) {
      throw StateError(
        'Transaction was updated, but the wallet could not refresh.',
      );
    }
  }

  Future<void> deleteTransaction(int id) async {
    await _database.deleteTransaction(id);
    await loadTransactions();
    if (_loadError != null) {
      throw StateError(
        'Transaction was deleted, but the wallet could not refresh.',
      );
    }
  }

  Future<void> setAllowancePeriodEndDate(DateTime? endDate) async {
    final allowance = currentAllowance;
    if (allowance == null) {
      throw StateError('Add an allowance before setting an end date.');
    }

    await updateTransaction(
      allowance.copyWith(
        periodEndDate: endDate,
        clearPeriodEndDate: endDate == null,
      ),
    );
  }
}
