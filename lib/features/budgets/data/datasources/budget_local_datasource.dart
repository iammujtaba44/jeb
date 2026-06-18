import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/features/budgets/data/models/budget_model.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/transactions/data/datasources/app_database.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<void> upsertBudget(Budget budget);
  Future<void> removeBudget(String? categoryId);
}

final class BudgetLocalDataSourceImpl implements BudgetLocalDataSource {
  const BudgetLocalDataSourceImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<BudgetModel>> getBudgets() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbConstants.budgetsTable,
        where: '${DbConstants.columnIsDeleted} = 0',
      );
      return rows.map(BudgetModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load budgets: $error');
    }
  }

  @override
  Future<void> upsertBudget(Budget budget) async {
    try {
      final db = await _appDatabase.database;
      final BudgetModel model =
          BudgetModel.fromEntity(budget, updatedAt: DateTime.now());
      await db.insert(
        DbConstants.budgetsTable,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to save budget: $error');
    }
  }

  @override
  Future<void> removeBudget(String? categoryId) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DbConstants.budgetsTable,
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[categoryId ?? DbConstants.overallBudgetKey],
      );
    } catch (error) {
      throw CacheException('Failed to remove budget: $error');
    }
  }
}
