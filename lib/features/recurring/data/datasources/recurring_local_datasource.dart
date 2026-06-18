import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:jeb/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:jeb/features/transactions/data/datasources/app_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

abstract interface class RecurringLocalDataSource {
  Future<List<RecurringTransactionModel>> getRecurringTransactions();
  Future<void> upsertRecurringTransaction(RecurringTransaction rule);
  Future<void> deleteRecurringTransaction(String id);
  Future<int> materializeDue(DateTime asOf);
}

final class RecurringLocalDataSourceImpl implements RecurringLocalDataSource {
  const RecurringLocalDataSourceImpl(this._appDatabase, this._uuid);

  final AppDatabase _appDatabase;
  final Uuid _uuid;

  /// Hard cap on occurrences generated per rule per run, guarding against a
  /// pathologically old start date producing an unbounded backfill.
  static const int _maxOccurrencesPerRule = 1000;

  @override
  Future<List<RecurringTransactionModel>> getRecurringTransactions() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbConstants.recurringTransactionsTable,
        where: '${DbConstants.columnIsDeleted} = 0',
        orderBy: '${DbConstants.columnNextDueDate} ASC',
      );
      return rows.map(RecurringTransactionModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load recurring transactions: $error');
    }
  }

  @override
  Future<void> upsertRecurringTransaction(RecurringTransaction rule) async {
    try {
      final db = await _appDatabase.database;
      final RecurringTransactionModel model =
          RecurringTransactionModel.fromEntity(rule, updatedAt: DateTime.now());
      await db.insert(
        DbConstants.recurringTransactionsTable,
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to save recurring transaction: $error');
    }
  }

  @override
  Future<void> deleteRecurringTransaction(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.delete(
        DbConstants.recurringTransactionsTable,
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[id],
      );
    } catch (error) {
      throw CacheException('Failed to delete recurring transaction: $error');
    }
  }

  @override
  Future<int> materializeDue(DateTime asOf) async {
    try {
      final db = await _appDatabase.database;
      return await db.transaction<int>((Transaction txn) async {
        final rows = await txn.query(
          DbConstants.recurringTransactionsTable,
          where: '${DbConstants.columnIsDeleted} = 0',
        );
        final int now = DateTime.now().millisecondsSinceEpoch;
        int generated = 0;

        for (final row in rows) {
          final RecurringTransactionModel rule =
              RecurringTransactionModel.fromMap(row);
          DateTime due = rule.nextDueDate;
          bool advanced = false;
          int guard = 0;

          while (!due.isAfter(asOf) &&
              (rule.endDate == null || !due.isAfter(rule.endDate!)) &&
              guard < _maxOccurrencesPerRule) {
            await txn.insert(DbConstants.transactionsTable, <String, dynamic>{
              DbConstants.columnId: _uuid.v4(),
              DbConstants.columnAmount: rule.amount,
              DbConstants.columnCurrencyCode: rule.currencyCode,
              DbConstants.columnCategoryId: rule.categoryId,
              DbConstants.columnNote: rule.note,
              DbConstants.columnDate: due.millisecondsSinceEpoch,
              DbConstants.columnType: rule.type.storageValue,
              DbConstants.columnRecurringId: rule.id,
              DbConstants.columnUpdatedAt: now,
              DbConstants.columnIsDeleted: 0,
            });
            generated++;
            guard++;
            advanced = true;
            due = rule.frequency.nextAfter(due);
          }

          if (advanced) {
            await txn.update(
              DbConstants.recurringTransactionsTable,
              <String, dynamic>{
                DbConstants.columnNextDueDate: due.millisecondsSinceEpoch,
                DbConstants.columnUpdatedAt: now,
              },
              where: '${DbConstants.columnId} = ?',
              whereArgs: <String>[rule.id],
            );
          }
        }
        return generated;
      });
    } catch (error) {
      throw CacheException('Failed to materialize recurring transactions: '
          '$error');
    }
  }
}
