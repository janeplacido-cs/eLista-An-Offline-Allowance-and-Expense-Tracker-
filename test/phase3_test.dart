import 'package:elista/database/db_helper.dart';
import 'package:elista/models/budget_model.dart';
import 'package:elista/models/transaction_model.dart';
import 'package:elista/providers/budget_provider.dart';
import 'package:elista/providers/profile_provider.dart';
import 'package:elista/providers/wallet_provider.dart';
import 'package:elista/screens/budget_screen.dart';
import 'package:elista/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  test('budget spending respects period, category, and transaction type', () {
    final database = _BudgetMemoryDatabase();
    final provider = BudgetProvider(database: database);
    final now = DateTime(2024, 6, 12, 12);
    final transactions = [
      _transaction(
        type: TransactionModel.expenseType,
        amount: 40,
        category: 'Food',
        date: DateTime(2024, 6, 10),
      ),
      _transaction(
        type: TransactionModel.expenseType,
        amount: 15,
        category: 'Food',
        date: DateTime(2024, 6, 16),
      ),
      _transaction(
        type: TransactionModel.expenseType,
        amount: 20,
        category: 'Transport',
        date: DateTime(2024, 6, 11),
      ),
      _transaction(
        type: TransactionModel.expenseType,
        amount: 5,
        category: 'Food',
        date: DateTime(2024, 6, 1),
      ),
      _transaction(
        type: TransactionModel.allowanceType,
        amount: 100,
        category: 'Allowance',
        date: DateTime(2024, 6, 12),
      ),
      _transaction(
        type: TransactionModel.expenseType,
        amount: 90,
        category: 'Food',
        date: DateTime(2024, 6, 17),
      ),
    ];

    final weeklyFood = BudgetModel(
      category: 'Food',
      limitAmount: 50,
      period: BudgetModel.weeklyPeriod,
      createdAt: now,
    );
    final monthlyOverall = BudgetModel(
      limitAmount: 200,
      period: BudgetModel.monthlyPeriod,
      createdAt: now,
    );

    expect(provider.spentFor(weeklyFood, transactions, now: now), 55);
    expect(provider.spentFor(monthlyOverall, transactions, now: now), 170);
  });

  testWidgets('sets an overall weekly budget and shows live progress', (
    tester,
  ) async {
    final now = DateTime.now();
    final database = _BudgetMemoryDatabase(
      transactions: [
        _transaction(
          id: 1,
          type: TransactionModel.expenseType,
          amount: 40,
          category: 'Food',
          date: now,
        ),
      ],
    );
    final wallet = WalletProvider(database: database);
    final budgets = BudgetProvider(database: database);
    await Future.wait([wallet.loadTransactions(), budgets.loadBudgets()]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: wallet),
          ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
        ],
        child: const MaterialApp(home: BudgetScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-budget')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('budget-limit')), '50');
    await tester.tap(find.text('Save budget'));
    await tester.pumpAndSettle();

    expect(budgets.budgets, hasLength(1));
    expect(budgets.budgets.single.isOverall, isTrue);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets('zero allowance and zero budget render safely', (tester) async {
    final database = _BudgetMemoryDatabase();
    final wallet = WalletProvider(database: database);
    final budgets = BudgetProvider(database: database);
    await Future.wait([wallet.loadTransactions(), budgets.loadBudgets()]);
    await budgets.saveBudget(
      BudgetModel(
        category: 'Food',
        limitAmount: 0,
        period: BudgetModel.weeklyPeriod,
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: wallet),
          ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
        ],
        child: const MaterialApp(home: BudgetScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('left'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('budget-donut'))),
      const Size(92, 92),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('budget overview shows database totals and category progress', (
    tester,
  ) async {
    final now = DateTime.now();
    final database = _BudgetMemoryDatabase(
      transactions: [
        _transaction(
          type: TransactionModel.allowanceType,
          amount: 1000,
          category: 'Allowance',
          date: now,
        ),
        _transaction(
          type: TransactionModel.expenseType,
          amount: 350,
          category: 'Food',
          date: now,
        ),
        _transaction(
          type: TransactionModel.expenseType,
          amount: 150,
          category: 'Transport',
          date: now,
        ),
        _transaction(
          type: TransactionModel.expenseType,
          amount: 100,
          category: 'School',
          date: now,
        ),
        _transaction(
          type: TransactionModel.expenseType,
          amount: 50,
          category: 'Other',
          date: now,
        ),
      ],
    );
    final wallet = WalletProvider(database: database);
    final budgets = BudgetProvider(database: database);
    await Future.wait([wallet.loadTransactions(), budgets.loadBudgets()]);
    await budgets.saveBudget(
      BudgetModel(
        category: 'Food',
        limitAmount: 500,
        period: BudgetModel.weeklyPeriod,
        createdAt: now,
      ),
    );
    await budgets.saveBudget(
      BudgetModel(
        category: 'Transport',
        limitAmount: 300,
        period: BudgetModel.weeklyPeriod,
        createdAt: now,
      ),
    );
    await budgets.saveBudget(
      BudgetModel(
        category: 'School',
        limitAmount: 250,
        period: BudgetModel.weeklyPeriod,
        createdAt: now,
      ),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: wallet),
          ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
        ],
        child: const MaterialApp(home: BudgetScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('₱1,000.00'), findsOneWidget);
    expect(find.text('₱650.00'), findsOneWidget);
    expect(find.text('₱350.00'), findsNWidgets(3));
    expect(find.text('65%'), findsOneWidget);
    expect(find.text('35%'), findsOneWidget);
    expect(find.text('70% of category budget spent'), findsOneWidget);
    expect(find.text('50% of category budget spent'), findsOneWidget);
    expect(find.text('40% of category budget spent'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Other'), 100);
    expect(find.text('0% of category budget spent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home dashboard shows the period controls and weekly summary', (
    tester,
  ) async {
    final now = DateTime.now();
    final database = _BudgetMemoryDatabase(
      transactions: [
        _transaction(
          type: TransactionModel.expenseType,
          amount: 50,
          category: 'Food',
          date: now,
        ),
      ],
    );
    final wallet = WalletProvider(database: database);
    final budgets = BudgetProvider(database: database);
    final profile = ProfileProvider();
    await Future.wait([wallet.loadTransactions(), budgets.loadBudgets()]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: wallet),
          ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
          ChangeNotifierProvider<ProfileProvider>.value(value: profile),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('This month'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('This Week'), 300);
    await tester.pumpAndSettle();
    expect(find.text('This Week'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

TransactionModel _transaction({
  int? id,
  required String type,
  required double amount,
  required String category,
  required DateTime date,
}) {
  return TransactionModel.create(
    id: id,
    type: type,
    amount: amount,
    category: category,
    date: date,
  );
}

class _BudgetMemoryDatabase implements DbHelper {
  _BudgetMemoryDatabase({List<TransactionModel> transactions = const []})
    : transactions = List.of(transactions);

  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets = [];
  int _nextBudgetId = 1;

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    transactions.add(
      transaction.copyWith(id: transaction.id ?? transactions.length + 1),
    );
    return transaction.id ?? transactions.length;
  }

  @override
  Future<List<TransactionModel>> getTransactions() async =>
      List.of(transactions);

  @override
  Future<TransactionModel?> getTransaction(int id) async {
    for (final transaction in transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  @override
  Future<int> updateTransaction(TransactionModel transaction) async => 0;

  @override
  Future<int> deleteTransaction(int id) async => 0;

  @override
  Future<int> insertBudget(BudgetModel budget) async {
    final id = budget.id ?? _nextBudgetId++;
    budgets.add(_withId(budget, id));
    return id;
  }

  @override
  Future<List<BudgetModel>> getBudgets() async => List.of(budgets);

  @override
  Future<BudgetModel?> getBudget(int id) async {
    for (final budget in budgets) {
      if (budget.id == id) return budget;
    }
    return null;
  }

  @override
  Future<int> updateBudget(BudgetModel budget) async {
    final index = budgets.indexWhere((item) => item.id == budget.id);
    if (index < 0) return 0;
    budgets[index] = budget;
    return 1;
  }

  @override
  Future<int> deleteBudget(int id) async {
    final length = budgets.length;
    budgets.removeWhere((budget) => budget.id == id);
    return length - budgets.length;
  }

  @override
  Future<void> clearAllData() async {
    transactions.clear();
    budgets.clear();
  }

  BudgetModel _withId(BudgetModel budget, int id) {
    return BudgetModel(
      id: id,
      category: budget.category,
      limitAmount: budget.limitAmount,
      period: budget.period,
      createdAt: budget.createdAt,
    );
  }
}
