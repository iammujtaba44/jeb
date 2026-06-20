import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/features/transactions/data/datasources/default_categories.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection lifecycle and schema. Opened lazily and reused.
final class AppDatabase {
  AppDatabase();

  Database? _database;

  Future<Database> get database async => _database ??= await _open();

  Future<Database> _open() async {
    final directory = await getApplicationDocumentsDirectory();
    final String path = p.join(directory.path, DbConstants.databaseName);
    return openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createTransactionsTableSql);
    await db.execute(_createCategoriesTableSql);
    await db.execute(_createBudgetsTableSql);
    await db.execute(_createRecurringTransactionsTableSql);
    await db.execute(_createPlansTableSql);
    await db.execute(_createPlanPaymentsTableSql);
    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createBudgetsTableSql);
    }
    if (oldVersion < 3) {
      await db.execute(_createRecurringTransactionsTableSql);
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE ${DbConstants.transactionsTable} '
        'ADD COLUMN ${DbConstants.columnRecurringId} TEXT',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE ${DbConstants.transactionsTable} '
        'ADD COLUMN ${DbConstants.columnReceiptPath} TEXT',
      );
    }
    if (oldVersion < 6) {
      await db.execute(_createPlansTableSql);
      await db.execute(_createPlanPaymentsTableSql);
    }
    if (oldVersion < 7) {
      // plan_payments created at v6 lacked receipt_paths; add it if missing.
      try {
        await db.execute(
          'ALTER TABLE ${DbConstants.planPaymentsTable} '
          'ADD COLUMN ${DbConstants.columnReceiptPaths} TEXT',
        );
      } catch (_) {
        // Column already present (table created fresh with the latest schema).
      }
    }
  }

  Future<void> _seedCategories(Database db) async {
    final Batch batch = db.batch();
    for (final CategoryModel category in DefaultCategories.seed()) {
      batch.insert(DbConstants.categoriesTable, category.toMap());
    }
    await batch.commit(noResult: true);
  }

  static const String _createTransactionsTableSql =
      'CREATE TABLE ${DbConstants.transactionsTable} ('
      '${DbConstants.columnId} TEXT PRIMARY KEY, '
      '${DbConstants.columnAmount} REAL NOT NULL, '
      '${DbConstants.columnCurrencyCode} TEXT NOT NULL, '
      '${DbConstants.columnCategoryId} TEXT NOT NULL, '
      '${DbConstants.columnNote} TEXT, '
      '${DbConstants.columnDate} INTEGER NOT NULL, '
      '${DbConstants.columnType} TEXT NOT NULL, '
      '${DbConstants.columnRecurringId} TEXT, '
      '${DbConstants.columnReceiptPath} TEXT, '
      '${DbConstants.columnUpdatedAt} INTEGER NOT NULL, '
      '${DbConstants.columnIsDeleted} INTEGER NOT NULL DEFAULT 0'
      ')';

  static const String _createCategoriesTableSql =
      'CREATE TABLE ${DbConstants.categoriesTable} ('
      '${DbConstants.columnId} TEXT PRIMARY KEY, '
      '${DbConstants.columnName} TEXT NOT NULL, '
      '${DbConstants.columnIconCodePoint} INTEGER NOT NULL, '
      '${DbConstants.columnColorValue} INTEGER NOT NULL, '
      '${DbConstants.columnType} TEXT NOT NULL, '
      '${DbConstants.columnUpdatedAt} INTEGER NOT NULL, '
      '${DbConstants.columnIsDeleted} INTEGER NOT NULL DEFAULT 0'
      ')';

  static const String _createBudgetsTableSql =
      'CREATE TABLE ${DbConstants.budgetsTable} ('
      '${DbConstants.columnId} TEXT PRIMARY KEY, '
      '${DbConstants.columnLimitAmount} REAL NOT NULL, '
      '${DbConstants.columnUpdatedAt} INTEGER NOT NULL, '
      '${DbConstants.columnIsDeleted} INTEGER NOT NULL DEFAULT 0'
      ')';

  static const String _createRecurringTransactionsTableSql =
      'CREATE TABLE ${DbConstants.recurringTransactionsTable} ('
      '${DbConstants.columnId} TEXT PRIMARY KEY, '
      '${DbConstants.columnAmount} REAL NOT NULL, '
      '${DbConstants.columnCurrencyCode} TEXT NOT NULL, '
      '${DbConstants.columnCategoryId} TEXT NOT NULL, '
      '${DbConstants.columnNote} TEXT, '
      '${DbConstants.columnType} TEXT NOT NULL, '
      '${DbConstants.columnFrequency} TEXT NOT NULL, '
      '${DbConstants.columnStartDate} INTEGER NOT NULL, '
      '${DbConstants.columnNextDueDate} INTEGER NOT NULL, '
      '${DbConstants.columnEndDate} INTEGER, '
      '${DbConstants.columnUpdatedAt} INTEGER NOT NULL, '
      '${DbConstants.columnIsDeleted} INTEGER NOT NULL DEFAULT 0'
      ')';

  static const String _createPlansTableSql =
      'CREATE TABLE ${DbConstants.plansTable} ('
      '${DbConstants.columnId} TEXT PRIMARY KEY, '
      '${DbConstants.columnName} TEXT NOT NULL, '
      '${DbConstants.columnKind} TEXT NOT NULL, '
      '${DbConstants.columnTargetAmount} REAL, '
      '${DbConstants.columnInstallmentAmount} REAL, '
      '${DbConstants.columnCurrencyCode} TEXT NOT NULL, '
      '${DbConstants.columnNote} TEXT, '
      '${DbConstants.columnDate} INTEGER NOT NULL, '
      '${DbConstants.columnUpdatedAt} INTEGER NOT NULL, '
      '${DbConstants.columnIsDeleted} INTEGER NOT NULL DEFAULT 0'
      ')';

  static const String _createPlanPaymentsTableSql =
      'CREATE TABLE ${DbConstants.planPaymentsTable} ('
      '${DbConstants.columnId} TEXT PRIMARY KEY, '
      '${DbConstants.columnPlanId} TEXT NOT NULL, '
      '${DbConstants.columnAmount} REAL NOT NULL, '
      '${DbConstants.columnDate} INTEGER NOT NULL, '
      '${DbConstants.columnNote} TEXT, '
      '${DbConstants.columnReceiptPaths} TEXT, '
      '${DbConstants.columnUpdatedAt} INTEGER NOT NULL, '
      '${DbConstants.columnIsDeleted} INTEGER NOT NULL DEFAULT 0'
      ')';
}
