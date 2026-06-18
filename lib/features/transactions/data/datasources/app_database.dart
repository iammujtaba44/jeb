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
    await _seedCategories(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createBudgetsTableSql);
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
}
