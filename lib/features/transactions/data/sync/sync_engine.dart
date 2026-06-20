import 'dart:io';

import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/core/services/receipt_store.dart';
import 'package:jeb/features/accounts/data/datasources/accounts_local_datasource.dart';
import 'package:jeb/features/accounts/data/models/account_model.dart';
import 'package:jeb/features/accounts/data/models/transfer_model.dart';
import 'package:jeb/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:jeb/features/budgets/data/models/budget_model.dart';
import 'package:jeb/features/plans/data/datasources/plans_local_datasource.dart';
import 'package:jeb/features/plans/data/models/plan_model.dart';
import 'package:jeb/features/plans/data/models/plan_payment_model.dart';
import 'package:jeb/features/recurring/data/datasources/recurring_local_datasource.dart';
import 'package:jeb/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:jeb/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/transactions/data/datasources/cloud_file_store.dart';
import 'package:jeb/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:jeb/features/transactions/data/models/category_model.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';
import 'package:jeb/features/transactions/data/sync/sync_merge.dart';
import 'package:jeb/features/transactions/data/sync/sync_snapshot.dart';

/// Two-way sync: pull the remote snapshot, merge newer records into the local
/// store (last-write-wins), then push the merged snapshot back. Covers
/// transactions, categories, budgets, recurring rules, and preferences, and
/// syncs receipt photo files alongside.
class SyncEngine {
  const SyncEngine({
    required TransactionLocalDataSource local,
    required BudgetLocalDataSource budgets,
    required RecurringLocalDataSource recurring,
    required PlansLocalDataSource plans,
    required AccountsLocalDataSource accounts,
    required SettingsLocalDataSource settings,
    required ReceiptStore receipts,
    required CloudFileStore cloudFileStore,
  })  : _local = local,
        _budgets = budgets,
        _recurring = recurring,
        _plans = plans,
        _accounts = accounts,
        _settings = settings,
        _receipts = receipts,
        _cloudFileStore = cloudFileStore;

  final TransactionLocalDataSource _local;
  final BudgetLocalDataSource _budgets;
  final RecurringLocalDataSource _recurring;
  final PlansLocalDataSource _plans;
  final AccountsLocalDataSource _accounts;
  final SettingsLocalDataSource _settings;
  final ReceiptStore _receipts;
  final CloudFileStore _cloudFileStore;

  Future<void> sync() async {
    final SyncSnapshot remote = await _readRemote();
    await _applyRemote(remote);
    await _pushMerged();
    await _syncReceiptFiles();
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

    final List<PlanModel> plansToApply = SyncMerge.recordsToApply<PlanModel>(
      local: await _plans.getAllPlansForSync(),
      remote: remote.plans,
      idOf: (PlanModel m) => m.id,
      updatedAtOf: (PlanModel m) => m.updatedAt,
    );
    for (final PlanModel model in plansToApply) {
      await _plans.putPlan(model);
    }

    final List<PlanPaymentModel> paymentsToApply =
        SyncMerge.recordsToApply<PlanPaymentModel>(
      local: await _plans.getAllPaymentsForSync(),
      remote: remote.planPayments,
      idOf: (PlanPaymentModel m) => m.id,
      updatedAtOf: (PlanPaymentModel m) => m.updatedAt,
    );
    for (final PlanPaymentModel model in paymentsToApply) {
      await _plans.putPayment(model);
    }

    final List<AccountModel> accountsToApply =
        SyncMerge.recordsToApply<AccountModel>(
      local: await _accounts.getAllAccountsForSync(),
      remote: remote.accounts,
      idOf: (AccountModel m) => m.id,
      updatedAtOf: (AccountModel m) => m.updatedAt,
    );
    for (final AccountModel model in accountsToApply) {
      await _accounts.putAccount(model);
    }

    final List<TransferModel> transfersToApply =
        SyncMerge.recordsToApply<TransferModel>(
      local: await _accounts.getAllTransfersForSync(),
      remote: remote.transfers,
      idOf: (TransferModel m) => m.id,
      updatedAtOf: (TransferModel m) => m.updatedAt,
    );
    for (final TransferModel model in transfersToApply) {
      await _accounts.putTransfer(model);
    }

    await _applySettings(remote.settings);
  }

  /// Last-write-wins for preferences, keeping this device's [lastSyncedAt].
  Future<void> _applySettings(AppSettings? remote) async {
    if (remote == null) return;
    final AppSettings local = await _settings.read();
    if (remote.updatedAtMs > local.updatedAtMs) {
      // Keep this device's own onboarding flag + last-synced time.
      await _settings.write(remote.copyWith(
        lastSyncedAt: local.lastSyncedAt,
        onboardingComplete: local.onboardingComplete,
      ));
    }
  }

  Future<void> _pushMerged() async {
    final SyncSnapshot merged = SyncSnapshot(
      transactions: await _local.getAllTransactionsForSync(),
      categories: await _local.getAllCategoriesForSync(),
      budgets: await _budgets.getAllBudgetsForSync(),
      recurring: await _recurring.getAllRecurringForSync(),
      plans: await _plans.getAllPlansForSync(),
      planPayments: await _plans.getAllPaymentsForSync(),
      accounts: await _accounts.getAllAccountsForSync(),
      transfers: await _accounts.getAllTransfersForSync(),
      settings: await _settings.read(),
    );
    await _cloudFileStore.writeSnapshot(merged.toJson());
  }

  /// Uploads receipt photos missing remotely and downloads any missing locally.
  /// Best-effort: a failed transfer never blocks the data sync.
  Future<void> _syncReceiptFiles() async {
    try {
      await _receipts.init();
      final List<TransactionModel> all =
          await _local.getAllTransactionsForSync();
      final List<PlanPaymentModel> payments =
          await _plans.getAllPaymentsForSync();
      final Set<String> withReceipts = <String>{
        for (final TransactionModel t in all)
          if (!t.isDeleted && t.receiptPath != null) t.receiptPath!,
        for (final PlanPaymentModel p in payments)
          if (!p.isDeleted) ...p.receiptPaths,
      };
      if (withReceipts.isEmpty) return;

      final Set<String> cloudFiles =
          (await _cloudFileStore.listFiles()).toSet();

      for (final String relative in withReceipts) {
        final String localPath = _receipts.absolutePath(relative);
        final bool localExists = File(localPath).existsSync();
        try {
          if (localExists && !cloudFiles.contains(relative)) {
            await _cloudFileStore.uploadFile(localPath, relative);
          } else if (!localExists && cloudFiles.contains(relative)) {
            await _cloudFileStore.downloadFile(relative, localPath);
          }
        } catch (_) {
          // Skip this receipt; continue with the rest.
        }
      }
    } catch (_) {
      // Receipt sync is best-effort.
    }
  }

  /// Stable sync id for a budget (the overall budget uses a sentinel key).
  static String _budgetId(BudgetModel m) =>
      m.categoryId ?? DbConstants.overallBudgetKey;
}
