import 'package:elista/database/db_helper.dart';
import 'package:elista/models/budget_model.dart';
import 'package:elista/models/transaction_model.dart';
import 'package:elista/providers/budget_provider.dart';
import 'package:elista/providers/profile_provider.dart';
import 'package:elista/providers/pin_lock_provider.dart';
import 'package:elista/providers/theme_provider.dart';
import 'package:elista/providers/wallet_provider.dart';
import 'package:elista/screens/add_transaction_screen.dart';
import 'package:elista/screens/history_screen.dart';
import 'package:elista/screens/setup_screen.dart';
import 'package:elista/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  testWidgets('expense form defaults to Food and validates a blank amount', (
    tester,
  ) async {
    final database = _MemoryDbHelper();
    final wallet = WalletProvider(database: database);
    await wallet.loadTransactions();

    await tester.pumpWidget(
      ChangeNotifierProvider<WalletProvider>.value(
        value: wallet,
        child: const MaterialApp(home: AddTransactionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('AMOUNT SPENT'), findsOneWidget);
    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.textContaining('Today,'), findsOneWidget);
    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: find.byKey(const ValueKey('transaction-amount')),
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .filled,
      isFalse,
    );

    await tester.ensureVisible(find.text('Save Expense'));
    await tester.tap(find.text('Save Expense'));
    await tester.pumpAndSettle();

    expect(find.text('Enter an amount greater than zero.'), findsOneWidget);
    expect(database.transactions, isEmpty);
  });

  testWidgets('first-run setup saves the profile and PIN without allowance', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final database = _MemoryDbHelper();
    final wallet = WalletProvider(database: database);
    final profile = ProfileProvider();
    final budgets = BudgetProvider(database: database);
    final theme = ThemeProvider();
    final pinLock = PinLockProvider(storage: _MemoryPinStorage());
    await Future.wait([
      wallet.loadTransactions(),
      profile.loadProfile(),
      budgets.loadBudgets(),
      theme.loadTheme(),
    ]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<WalletProvider>.value(value: wallet),
          ChangeNotifierProvider<ProfileProvider>.value(value: profile),
          ChangeNotifierProvider<BudgetProvider>.value(value: budgets),
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
          ChangeNotifierProvider<PinLockProvider>.value(value: pinLock),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const SetupScreen(),
        ),
      ),
    );

    await tester.enterText(find.byKey(const ValueKey('setup-name')), 'Alex');
    await tester.enterText(find.byKey(const ValueKey('setup-pin')), '1234');
    await tester.enterText(
      find.byKey(const ValueKey('setup-confirm-pin')),
      '1234',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('setup-get-started')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('setup-get-started')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(profile.name, 'Alex');
    expect(profile.isSetupComplete, isTrue);
    expect(pinLock.isEnabled, isTrue);
    expect(wallet.totalAllowance, 0);
  });

  testWidgets('records an allowance and updates the wallet balance', (
    tester,
  ) async {
    final database = _MemoryDbHelper();
    final wallet = WalletProvider(database: database);
    await wallet.loadTransactions();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: wallet,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const AddTransactionScreen(
                      initialType: TransactionModel.allowanceType,
                    ),
                  ),
                ),
                child: const Text('Open form'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '500',
    );
    await tester.ensureVisible(find.text('Save Allowance'));
    await tester.tap(find.text('Save Allowance'));
    await tester.pumpAndSettle();

    expect(wallet.totalAllowance, 500);
    expect(wallet.totalExpenses, 0);
    expect(wallet.remainingBalance, 500);
    expect(database.transactions.single.category, 'Weekly allowance');
  });

  testWidgets('allowance end date is optional and saves a quick-pick date', (
    tester,
  ) async {
    final database = _MemoryDbHelper();
    final wallet = WalletProvider(database: database);
    await wallet.loadTransactions();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: wallet,
        child: const MaterialApp(
          home: AddTransactionScreen(
            initialType: TransactionModel.allowanceType,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ALLOWANCE ENDS ON'), findsOneWidget);
    expect(find.text('DATE'), findsNothing);
    expect(
      tester
          .widget<InputDecorator>(
            find.descendant(
              of: find.byKey(const ValueKey('transaction-amount')),
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration
          .filled,
      isFalse,
    );
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '500',
    );
    await tester.tap(find.text('1 week'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save Allowance'));
    final beforeSave = DateTime.now();
    await tester.tap(find.text('Save Allowance'));
    await tester.pumpAndSettle();

    final allowance = wallet.currentAllowance!;
    expect(
      allowance.date.isAfter(beforeSave.subtract(const Duration(seconds: 1))),
      isTrue,
    );
    expect(
      allowance.date.isBefore(DateTime.now().add(const Duration(seconds: 1))),
      isTrue,
    );
    expect(
      allowance.periodEndDate,
      DateUtils.dateOnly(DateTime.now().add(const Duration(days: 7))),
    );
  });

  testWidgets('allowance with a past end date cannot be saved', (tester) async {
    final yesterday = DateUtils.dateOnly(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    final database = _MemoryDbHelper(
      transactions: [
        TransactionModel.create(
          id: 1,
          type: TransactionModel.allowanceType,
          amount: 500,
          category: 'Allowance',
          date: yesterday.subtract(const Duration(days: 7)),
          periodEndDate: yesterday,
        ),
      ],
    );
    final wallet = WalletProvider(database: database);
    await wallet.loadTransactions();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: wallet,
        child: MaterialApp(
          home: AddTransactionScreen(transaction: wallet.currentAllowance),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Choose today or a later date.'), findsOneWidget);
    expect(database.transactions.single.periodEndDate, yesterday);
  });

  test('wallet exposes current-period date and today expense totals', () async {
    final now = DateTime.now();
    final database = _MemoryDbHelper(
      transactions: [
        TransactionModel.create(
          id: 1,
          type: TransactionModel.allowanceType,
          amount: 500,
          category: 'Allowance',
          date: now.subtract(const Duration(days: 14)),
          createdAt: now.subtract(const Duration(days: 14)),
        ),
        TransactionModel.create(
          id: 2,
          type: TransactionModel.allowanceType,
          amount: 700,
          category: 'Allowance',
          date: now.subtract(const Duration(days: 2)),
          createdAt: now.subtract(const Duration(days: 2)),
        ),
        TransactionModel.create(
          id: 3,
          type: TransactionModel.expenseType,
          amount: 25,
          category: 'Food',
          date: now,
        ),
      ],
    );
    final wallet = WalletProvider(database: database);
    await wallet.loadTransactions();

    expect(wallet.currentAllowance?.id, 2);
    expect(wallet.todayExpenses, 25);

    final endDate = DateUtils.dateOnly(now.add(const Duration(days: 5)));
    await wallet.setAllowancePeriodEndDate(endDate);
    expect(wallet.allowancePeriodEndDate, endDate);

    await wallet.setAllowancePeriodEndDate(null);
    expect(wallet.allowancePeriodEndDate, isNull);
    expect(database.transactions.first.periodEndDate, isNull);
  });

  testWidgets('groups history by date and exposes edit and delete actions', (
    tester,
  ) async {
    final now = DateTime.now();
    final database = _MemoryDbHelper(
      transactions: [
        TransactionModel.create(
          id: 1,
          type: TransactionModel.expenseType,
          amount: 25,
          category: 'Food',
          date: now,
        ),
        TransactionModel.create(
          id: 2,
          type: TransactionModel.allowanceType,
          amount: 200,
          category: 'Allowance',
          date: now.subtract(const Duration(days: 1)),
        ),
      ],
    );
    final wallet = WalletProvider(database: database);
    await wallet.loadTransactions();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: wallet,
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Allowance'), findsNWidgets(2));
    expect(find.byTooltip('Transaction actions'), findsNWidgets(2));

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('transaction-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-2')), findsNothing);
    await tester.tap(find.text('Allowance').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('transaction-1')), findsNothing);
    expect(find.byKey(const ValueKey('transaction-2')), findsOneWidget);
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Transaction actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('transaction-amount')),
      '30',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(wallet.totalExpenses, 30);

    await tester.tap(find.byTooltip('Transaction actions').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(wallet.totalExpenses, 0);
    expect(wallet.remainingBalance, 200);
  });

  testWidgets('history search combines with the transaction type filter', (
    tester,
  ) async {
    final now = DateTime.now();
    final database = _MemoryDbHelper(
      transactions: [
        TransactionModel.create(
          id: 1,
          type: TransactionModel.expenseType,
          amount: 80,
          category: 'Food',
          note: 'Lunch with classmates',
          date: now,
        ),
        TransactionModel.create(
          id: 2,
          type: TransactionModel.expenseType,
          amount: 30,
          category: 'Transport',
          note: 'Bus ride',
          date: now,
        ),
        TransactionModel.create(
          id: 3,
          type: TransactionModel.allowanceType,
          amount: 500,
          category: 'Weekly allowance',
          note: 'Lunch allowance',
          date: now.subtract(const Duration(hours: 1)),
        ),
      ],
    );
    final wallet = WalletProvider(database: database);
    await wallet.loadTransactions();

    await tester.pumpWidget(
      ChangeNotifierProvider<WalletProvider>.value(
        value: wallet,
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search transactions'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'lunch');
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('transaction-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-3')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-2')), findsNothing);

    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('transaction-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('transaction-3')), findsNothing);
    expect(find.byKey(const ValueKey('transaction-2')), findsNothing);
  });
}

class _MemoryPinStorage implements PinRecordStorage {
  String? record;

  @override
  Future<String?> readRecord() async => record;

  @override
  Future<void> writeRecord(String value) async {
    record = value;
  }

  @override
  Future<void> clearRecord() async {
    record = null;
  }
}

class _MemoryDbHelper implements DbHelper {
  _MemoryDbHelper({List<TransactionModel> transactions = const []})
    : transactions = List.of(transactions);

  final List<TransactionModel> transactions;
  final List<BudgetModel> budgets = [];
  int _nextId = 1;
  int _nextBudgetId = 1;

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<int> insertTransaction(TransactionModel transaction) async {
    final id = transaction.id ?? _nextId++;
    transactions.add(transaction.copyWith(id: id));
    return id;
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final result = List<TransactionModel>.of(transactions);
    result.sort((a, b) {
      final dateOrder = b.date.compareTo(a.date);
      if (dateOrder != 0) return dateOrder;
      final createdOrder = b.createdAt.compareTo(a.createdAt);
      return createdOrder != 0
          ? createdOrder
          : (b.id ?? 0).compareTo(a.id ?? 0);
    });
    return result;
  }

  @override
  Future<TransactionModel?> getTransaction(int id) async {
    for (final transaction in transactions) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  @override
  Future<int> updateTransaction(TransactionModel transaction) async {
    final index = transactions.indexWhere((item) => item.id == transaction.id);
    if (index < 0) return 0;
    transactions[index] = transaction;
    return 1;
  }

  @override
  Future<int> deleteTransaction(int id) async {
    final originalLength = transactions.length;
    transactions.removeWhere((transaction) => transaction.id == id);
    return originalLength - transactions.length;
  }

  @override
  Future<int> insertBudget(BudgetModel budget) async {
    final id = budget.id ?? _nextBudgetId++;
    budgets.add(
      BudgetModel(
        id: id,
        category: budget.category,
        limitAmount: budget.limitAmount,
        period: budget.period,
        createdAt: budget.createdAt,
      ),
    );
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
    final originalLength = budgets.length;
    budgets.removeWhere((budget) => budget.id == id);
    return originalLength - budgets.length;
  }

  @override
  Future<void> clearAllData() async {
    transactions.clear();
    budgets.clear();
  }
}
