import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:jeb/features/budgets/data/models/budget_model.dart';
import 'package:jeb/features/recurring/data/datasources/recurring_local_datasource.dart';
import 'package:jeb/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:jeb/features/transactions/data/datasources/cloud_file_store.dart';
import 'package:jeb/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';
import 'package:jeb/features/transactions/data/sync/sync_merge.dart';
import 'package:jeb/features/transactions/data/sync/sync_snapshot.dart';

/// Two-way sync: pull the remote snapshot, merge newer records into the local
/// store (last-write-wins), then push the merged snapshot back. Covers
/// transactions, categories, budgets, and recurring rules.
class SyncEngine {
  const SyncEngine({
    required TransactionLocalDataSource local,
    required BudgetLocalDataSource budgets,
    required RecurringLocalDataSource recurring,
    required CloudFileStore cloudFileStore,
  })  : _local = local,
        _budgets = budgets,
        _recurring = recurring,
        _cloudFileStore = cloudFileStore;

  final TransactionLocalDataSource _local;
  final BudgetLocalDataSource _budgets;
  final RecurringLocalDataSource _recurring;
  final CloudFileStore _cloudFileStore;

  Future<void> sync() async {
    final SyncSnapshot remote = await _readRemote();
    await _applyRemote(remote);
    await _pushMerged();
  }

  Future<SyncSnapshot> _readRemote() async {
    final String? raw = await _cloudFileStore.readSnapshot();
    return raw == null ? SyncSnapshot.empty() : SyncSnapshot.fromJson(raw);
  }

  Future<void> _applyRemote(SyncSnapshot remote) async {
    final List<TransactionModel> transactionsToApply =
        SyncMerge.recordsToApply<TransactionModel>(
      local: await _local.getAllTransactionsForSync(),
      remote: remote.transactions,
      idOf: (TransactionModel m) => m.id,
      updatedAtOf: (TransactionModel m) => m.updatedAt,
    );
    for (final TransactionModel model in transactionsToApply) {
      await _local.putTransaction(model);
    }

    final List<CategoryModel> categoriesToApply =
        SyncMerge.recordsToApply<CategoryModel>(
      local: await _local.getAllCategoriesForSync(),
      remote: remote.categories,
      idOf: (CategoryModel m) => m.id,
      updatedAtOf: (CategoryModel m) => m.updatedAt,
    );
    for (final CategoryModel model in categoriesToApply) {
      await _local.putCategory(model);
    }

    final List<BudgetModel> budgetsToApply =
        SyncMerge.recordsToApply<BudgetModel>(
      local: await _budgets.getAllBudgetsForSync(),
      remote: remote.budgets,
      idOf: _budgetId,
      updatedAtOf: (BudgetModel m) => m.updatedAt,
    );
    for (final BudgetModel model in budgetsToApply) {
      await _budgets.putBudget(model);
    }

    final List<RecurringTransactionModel> recurringToApply =
        SyncMerge.recordsToApply<RecurringTransactionModel>(
      local: await _recurring.getAllRecurringForSync(),
      remote: remote.recurring,
      idOf: (RecurringTransactionModel m) => m.id,
      updatedAtOf: (RecurringTransactionModel m) => m.updatedAt,
    );
    for (final RecurringTransactionModel model in recurringToApply) {
      await _recurring.putRecurring(model);
    }
  }

  Future<void> _pushMerged() async {
    final SyncSnapshot merged = SyncSnapshot(
      transactions: await _local.getAllTransactionsForSync(),
      categories: await _local.getAllCategoriesForSync(),
      budgets: await _budgets.getAllBudgetsForSync(),
      recurring: await _recurring.getAllRecurringForSync(),
    );
    await _cloudFileStore.writeSnapshot(merged.toJson());
  }

  /// Stable sync id for a budget (the overall budget uses a sentinel key).
  static String _budgetId(BudgetModel m) =>
      m.categoryId ?? DbConstants.overallBudgetKey;
}
