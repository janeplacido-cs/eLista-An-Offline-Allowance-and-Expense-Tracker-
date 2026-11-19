import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';

class DbHelper {
  DbHelper._();

  static final DbHelper instance = DbHelper._();

  static const String _transactionsTable = 'transactions';
  static const String _budgetsTable = 'budgets';

  Future<Database>? _database;

  Future<Database> get database => _database ??= _openDatabase();

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      path.join(databasePath, 'elista.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_transactionsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            category TEXT,
            note TEXT,
            date TEXT NOT NULL,
            created_at TEXT NOT NULL,
            period_end_date TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE $_budgetsTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            limit_amount REAL NOT NULL,
            period TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE $_transactionsTable ADD COLUMN period_end_date TEXT',
          );
        }
      },
    );
  }

  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return db.insert(_transactionsTable, transaction.toMap());
  }

  Future<List<TransactionModel>> getTransactions() async {
    final db = await database;
    final rows = await db.query(
      _transactionsTable,
      orderBy: 'date DESC, created_at DESC, id DESC',
    );
    return rows.map(TransactionModel.fromMap).toList(growable: false);
  }

  Future<TransactionModel?> getTransaction(int id) async {
    final db = await database;
    final rows = await db.query(
      _transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return TransactionModel.fromMap(rows.first);
  }

  Future<int> updateTransaction(TransactionModel transaction) async {
    final id = transaction.id;
    if (id == null) {
      throw ArgumentError.value(id, 'transaction.id', 'An ID is required.');
    }

    final db = await database;
    return db.update(
      _transactionsTable,
      transaction.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete(_transactionsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertBudget(BudgetModel budget) async {
    final db = await database;
    return db.insert(_budgetsTable, budget.toMap());
  }

  Future<List<BudgetModel>> getBudgets() async {
    final db = await database;
    final rows = await db.query(
      _budgetsTable,
      orderBy: 'period ASC, category COLLATE NOCASE ASC, id ASC',
    );
    return rows.map(BudgetModel.fromMap).toList(growable: false);
  }

  Future<BudgetModel?> getBudget(int id) async {
    final db = await database;
    final rows = await db.query(
      _budgetsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BudgetModel.fromMap(rows.first);
  }

  Future<int> updateBudget(BudgetModel budget) async {
    final id = budget.id;
    if (id == null) {
      throw ArgumentError.value(id, 'budget.id', 'An ID is required.');
    }

    final db = await database;
    return db.update(
      _budgetsTable,
      budget.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return db.delete(_budgetsTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete(_transactionsTable);
      await transaction.delete(_budgetsTable);
    });
  }
}
