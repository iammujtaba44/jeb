import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/features/accounts/data/models/account_model.dart';
import 'package:jeb/features/accounts/data/models/transfer_model.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/account_balance.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
import 'package:jeb/features/transactions/data/datasources/app_database.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class AccountsLocalDataSource {
  Future<List<AccountModel>> getAccounts();

  /// Archived (hidden) accounts, kept out of [getAccounts] and balances.
  Future<List<AccountModel>> getArchivedAccounts();
  Future<void> upsertAccount(Account account);
  Future<void> deleteAccount(String id);

  Future<List<TransferModel>> getTransfers();
  Future<void> upsertTransfer(Transfer transfer);
  Future<void> deleteTransfer(String id);

  /// Current balance per account id, each in the account's own currency.
  Future<Map<String, double>> balances();

  // Sync (include tombstones).
  Future<List<AccountModel>> getAllAccountsForSync();
  Future<void> putAccount(AccountModel model);
  Future<List<TransferModel>> getAllTransfersForSync();
  Future<void> putTransfer(TransferModel model);
}

final class AccountsLocalDataSourceImpl implements AccountsLocalDataSource {
  const AccountsLocalDataSourceImpl(this._appDatabase);

  final AppDatabase _appDatabase;

  @override
  Future<List<AccountModel>> getAccounts() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbConstants.accountsTable,
        where: '${DbConstants.columnIsDeleted} = 0 AND '
            '${DbConstants.columnArchived} = 0',
        orderBy: '${DbConstants.columnName} ASC',
      );
      return rows.map(AccountModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load accounts: $error');
    }
  }

  @override
  Future<List<AccountModel>> getArchivedAccounts() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbConstants.accountsTable,
        where: '${DbConstants.columnIsDeleted} = 0 AND '
            '${DbConstants.columnArchived} = 1',
        orderBy: '${DbConstants.columnName} ASC',
      );
      return rows.map(AccountModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load archived accounts: $error');
    }
  }

  @override
  Future<void> upsertAccount(Account account) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DbConstants.accountsTable,
        AccountModel.fromEntity(account, updatedAt: DateTime.now()).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to save account: $error');
    }
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      final db = await _appDatabase.database;
      final int now = DateTime.now().millisecondsSinceEpoch;
      // Soft-delete the account and any transfers touching it so balances and
      // sync stay consistent. Transactions keep their account_id but no longer
      // resolve to a live account, so they fall out of balance totals.
      await db.update(
        DbConstants.accountsTable,
        <String, Object?>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: now,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[id],
      );
      await db.update(
        DbConstants.transfersTable,
        <String, Object?>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: now,
        },
        where: '${DbConstants.columnFromAccountId} = ? OR '
            '${DbConstants.columnToAccountId} = ?',
        whereArgs: <String>[id, id],
      );
    } catch (error) {
      throw CacheException('Failed to delete account: $error');
    }
  }

  @override
  Future<List<TransferModel>> getTransfers() async {
    try {
      final db = await _appDatabase.database;
      final rows = await db.query(
        DbConstants.transfersTable,
        where: '${DbConstants.columnIsDeleted} = 0',
        orderBy: '${DbConstants.columnDate} DESC',
      );
      return rows.map(TransferModel.fromMap).toList();
    } catch (error) {
      throw CacheException('Failed to load transfers: $error');
    }
  }

  @override
  Future<void> upsertTransfer(Transfer transfer) async {
    try {
      final db = await _appDatabase.database;
      await db.insert(
        DbConstants.transfersTable,
        TransferModel.fromEntity(transfer, updatedAt: DateTime.now()).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (error) {
      throw CacheException('Failed to save transfer: $error');
    }
  }

  @override
  Future<void> deleteTransfer(String id) async {
    try {
      final db = await _appDatabase.database;
      await db.update(
        DbConstants.transfersTable,
        <String, Object?>{
          DbConstants.columnIsDeleted: 1,
          DbConstants.columnUpdatedAt: DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DbConstants.columnId} = ?',
        whereArgs: <String>[id],
      );
    } catch (error) {
      throw CacheException('Failed to delete transfer: $error');
    }
  }

  @override
  Future<Map<String, double>> balances() async {
    try {
      final db = await _appDatabase.database;
      final List<AccountModel> accounts = await getAccounts();
      final List<TransferModel> transfers = await getTransfers();

      final rows = await db.rawQuery(
        'SELECT ${DbConstants.columnAccountId} AS aid, '
        '${DbConstants.columnType} AS t, '
        'SUM(${DbConstants.columnAmount}) AS total '
        'FROM ${DbConstants.transactionsTable} '
        'WHERE ${DbConstants.columnIsDeleted} = 0 '
        'AND ${DbConstants.columnAccountId} IS NOT NULL '
        'GROUP BY ${DbConstants.columnAccountId}, ${DbConstants.columnType}',
      );

      final Map<String, double> income = <String, double>{};
      final Map<String, double> expense = <String, double>{};
      for (final Map<String, Object?> r in rows) {
        final String aid = r['aid'] as String;
        final double total = (r['total'] as num?)?.toDouble() ?? 0;
        if ((r['t'] as String) == TransactionType.income.storageValue) {
          income[aid] = total;
        } else {
          expense[aid] = total;
        }
      }

      return AccountBalance.compute(
        accounts: accounts,
        incomeByAccount: income,
        expenseByAccount: expense,
        transfers: transfers,
      );
    } catch (error) {
      throw CacheException('Failed to compute balances: $error');
    }
  }

  @override
  Future<List<AccountModel>> getAllAccountsForSync() async {
    final db = await _appDatabase.database;
    final rows = await db.query(DbConstants.accountsTable);
    return rows.map(AccountModel.fromMap).toList();
  }

  @override
  Future<void> putAccount(AccountModel model) async {
    final db = await _appDatabase.database;
    await db.insert(DbConstants.accountsTable, model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<TransferModel>> getAllTransfersForSync() async {
    final db = await _appDatabase.database;
    final rows = await db.query(DbConstants.transfersTable);
    return rows.map(TransferModel.fromMap).toList();
  }

  @override
  Future<void> putTransfer(TransferModel model) async {
    final db = await _appDatabase.database;
    await db.insert(DbConstants.transfersTable, model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
