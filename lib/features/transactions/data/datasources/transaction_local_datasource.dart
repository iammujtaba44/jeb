import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/features/transactions/data/datasources/app_database.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/search_criteria.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

/// On-device persistence. The source of truth for the UI.
abstract interface class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactionsForMonth(DateTime month);
  Future<List<TransactionModel>> searchTransactions(SearchCriteria criteria);
  Future<TransactionModel> upsertTransaction(Transaction transaction);
  Future<void> softDeleteTransaction(String id);
  Future<List<CategoryModel>> getCategories();

  // ── Category management (user-defined categories) ────────────────────
  Future<void> upsertCategory(Category category);
  Future<void> softDeleteCategory(String id);

  // ── Sync support: full snapshots (incl. tombstones) + verbatim writes ──
  Future<List<TransactionModel>> getAllTransactionsForSync();
  Future<List<CategoryModel>> getAllCategoriesForSync();

  /// Insert/replace preserving the model's own [updatedAt]/[isDeleted]
  /// (used when applying remote records during a merge).
  Future<void> putTransaction(TransactionModel model);
  Future<void> putCategory(CategoryModel model);
}

final class TransactionLocalDataSourceImpl
    implements TransactionLocalDataSource {
  const TransactionLocalDataSourceImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<TransactionModel>> getTransactionsForMonth(DateTime month) async {
    try {
      final db = await _appDatabase.database;
      final DateTime start = DateTime(month.year, month.month);
      final DateTime end = DateTime(month.year, month.month + 1);

      final List<Map<String, Object?>> rows = await db.query(
        DbConstants.transactionsTable,
        where: '${DbConstants.columnIsDeleted} = 0 '
            'AND ${DbConstants.columnDate} >= ? '
            'AND ${DbConstants.columnDate} < ?',
        whereArgs: <int>[
          start.millisecondsSinceEpoch,
          end.millisecondsSinceEpoch,
        ],
        orderBy: '${DbConstants.columnDate} DESC',
      );

      return rows.map(TransactionModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load transactions: $error');
    }
  }

  @override
  Future<List<TransactionModel>> searchTransactions(
    SearchCriteria criteria,
  ) async {
    try {
      final db = await _appDatabase.database;
      final List<String> where = <String>['${DbConstants.columnIsDeleted} = 0'];
      final List<Object?> args = <Object?>[];

      if (criteria.query.trim().isNotEmpty) {
        where.add('${DbConstants.columnNote} LIKE ?');
        args.add('%${criteria.query.trim()}%');
      }
      if (criteria.type != null) {
        where.add('${DbConstants.columnType} = ?');
        args.add(criteria.type!.storageValue);
      }
      if (criteria.categoryId != null) {
        where.add('${DbConstants.columnCategoryId} = ?');
        args.add(criteria.categoryId);
      }
      if (criteria.from != null) {
        where.add('${DbConstants.columnDate} >= ?');
        args.add(criteria.from!.millisecondsSinceEpoch);
      }
      if (criteria.to != null) {
        where.add('${DbConstants.columnDate} <= ?');
        args.add(criteria.to!.millisecondsSinceEpoch);
      }
      if (criteria.minAmount != null) {
        where.add('${DbConstants.columnAmount} >= ?');
        args.add(criteria.minAmount);
      }
      if (criteria.maxAmount != null) {
        where.add('${DbConstants.columnAmount} <= ?');
        args.add(criteria.maxAmount);
      }

      final List<Map<String, Object?>> rows = await db.query(
        DbConstants.transactionsTable,
        where: where.join(' AND '),
        whereArgs: args,
        orderBy: '${DbConstants.columnDate} DESC',
      );
      return rows.map(TransactionModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to search transactions: $error');
    }
  }

  @override
  Future<TransactionModel> upsertTransaction(Transaction transaction) async {
    try {
      final db = await _appDatabase.database;
      final TransactionModel model = TransactionModel.fromEntity(
        transaction,
        updatedAt: DateTime.now(),
      );
      await db.insert(
        DbConstants.transactionsTable,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return model;
    } catch (error) {
      throw CacheException('Failed to save transaction: $error');
    }
  }

  @override
  Future<void> softDeleteTransaction(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DbConstants.transactionsTable,
        <String, Object?>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[id],
      );
    } catch (error) {
      throw CacheException('Failed to delete transaction: $error');
    }
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    try {
      final db = await _appDatabase.database;
      final List<Map<String, Object?>> rows = await db.query(
        DbConstants.categoriesTable,
        where: '${DbConstants.columnIsDeleted} = 0',
        orderBy: '${DbConstants.columnName} ASC',
      );
      return rows.map(CategoryModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load categories: $error');
    }
  }

  @override
  Future<void> upsertCategory(Category category) async {
    try {
      final db = await _appDatabase.database;
      final CategoryModel model = CategoryModel(
        id: category.id,
        name: category.name,
        iconCodePoint: category.iconCodePoint,
        colorValue: category.colorValue,
        type: category.type,
        updatedAt: DateTime.now(),
      );
      await db.insert(
        DbConstants.categoriesTable,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to save category: $error');
    }
  }

  @override
  Future<void> softDeleteCategory(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DbConstants.categoriesTable,
        <String, Object?>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[id],
      );
    } catch (error) {
      throw CacheException('Failed to delete category: $error');
    }
  }

  @override
  Future<List<TransactionModel>> getAllTransactionsForSync() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(DbConstants.transactionsTable);
      return rows.map(TransactionModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to read transactions for sync: $error');
    }
  }

  @override
  Future<List<CategoryModel>> getAllCategoriesForSync() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(DbConstants.categoriesTable);
      return rows.map(CategoryModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to read categories for sync: $error');
    }
  }

  @override
  Future<void> putTransaction(TransactionModel model) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DbConstants.transactionsTable,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to apply remote transaction: $error');
    }
  }

  @override
  Future<void> putCategory(CategoryModel model) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DbConstants.categoriesTable,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to apply remote category: $error');
    }
  }
}
