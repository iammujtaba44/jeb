import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/constants/app_constants.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/usecases/get_budgets.dart';
import 'package:jeb/features/recurring/domain/usecases/materialize_due_transactions.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/add_transaction.dart';
import 'package:jeb/features/transactions/domain/usecases/delete_transaction.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/get_transactions_for_month.dart';
import 'package:jeb/features/transactions/domain/usecases/sync_data.dart';

part 'transactions_state.dart';

/// Drives the home screen: loads the current month's transactions + categories,
/// triggers sync, and handles deletes.
class TransactionsCubit extends Cubit<TransactionsState> {
  TransactionsCubit({
    required GetTransactionsForMonth getTransactionsForMonth,
    required GetCategories getCategories,
    required DeleteTransaction deleteTransaction,
    required SyncData syncData,
    required GetSettings getSettings,
    required AddTransaction addTransaction,
    required GetBudgets getBudgets,
    required MaterializeDueTransactions materializeDueTransactions,
  })  : _getTransactionsForMonth = getTransactionsForMonth,
        _getCategories = getCategories,
        _deleteTransaction = deleteTransaction,
        _syncData = syncData,
        _getSettings = getSettings,
        _addTransaction = addTransaction,
        _getBudgets = getBudgets,
        _materializeDueTransactions = materializeDueTransactions,
        super(const TransactionsInitial());

  final GetTransactionsForMonth _getTransactionsForMonth;
  final GetCategories _getCategories;
  final DeleteTransaction _deleteTransaction;
  final SyncData _syncData;
  final GetSettings _getSettings;
  final AddTransaction _addTransaction;
  final GetBudgets _getBudgets;
  final MaterializeDueTransactions _materializeDueTransactions;

  DateTime _month = _firstOfThisMonth();
  String _homeCurrency = AppConstants.defaultCurrencyCode;
  double? _overallBudget;
  Map<String, double> _categoryBudgets = <String, double>{};

  DateTime get month => _month;

  Future<void> load() async {
    emit(const TransactionsLoading());
    bool syncEnabled = true;
    final settingsResult = await _getSettings(const NoParams());
    settingsResult.fold(
      (_) {},
      (settings) {
        _homeCurrency = settings.defaultCurrencyCode;
        syncEnabled = settings.syncEnabled;
      },
    );
    if (syncEnabled) await _syncData(const NoParams());

    // Generate any recurring transactions that have come due since last open.
    await _materializeDueTransactions(DateTime.now());

    final budgetsResult = await _getBudgets(const NoParams());
    budgetsResult.fold((_) {}, (List<Budget> budgets) {
      _overallBudget = null;
      _categoryBudgets = <String, double>{};
      for (final Budget b in budgets) {
        if (b.isOverall) {
          _overallBudget = b.limitAmount;
        } else {
          _categoryBudgets[b.categoryId!] = b.limitAmount;
        }
      }
    });

    await _refreshFromCache();
  }

  Future<void> refresh() async {
    // Idempotent: only generates occurrences that have newly come due, so a
    // rule added elsewhere shows up as soon as the user returns to Home.
    await _materializeDueTransactions(DateTime.now());
    await _refreshFromCache();
  }

  Future<void> deleteTransaction(String id) async {
    final result = await _deleteTransaction(id);
    await result.fold(
      (failure) async => emit(TransactionsError(failure.message)),
      (_) async => _refreshFromCache(),
    );
  }

  /// Re-adds a previously deleted transaction (powers swipe-to-delete Undo).
  Future<void> restore(Transaction transaction) async {
    await _addTransaction(transaction);
    await _refreshFromCache();
  }

  Future<void> goToPreviousMonth() async {
    _month = DateTime(_month.year, _month.month - 1);
    await _refreshFromCache();
  }

  Future<void> goToNextMonth() async {
    final DateTime candidate = DateTime(_month.year, _month.month + 1);
    if (candidate.isAfter(_firstOfThisMonth())) return;
    _month = candidate;
    await _refreshFromCache();
  }

  /// Jump to any (non-future) month.
  Future<void> goToMonth(DateTime month) async {
    final DateTime normalized = DateTime(month.year, month.month);
    if (normalized.isAfter(_firstOfThisMonth())) return;
    _month = normalized;
    await _refreshFromCache();
  }

  static DateTime _firstOfThisMonth() {
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  Future<void> _refreshFromCache() async {
    final categoriesResult = await _getCategories(const NoParams());
    final transactionsResult = await _getTransactionsForMonth(_month);

    categoriesResult.fold(
      (failure) => emit(TransactionsError(failure.message)),
      (categories) => transactionsResult.fold(
        (failure) => emit(TransactionsError(failure.message)),
        (transactions) => emit(
          TransactionsLoaded(
            transactions: transactions,
            categories: categories,
            month: _month,
            homeCurrency: _homeCurrency,
            overallBudget: _overallBudget,
            categoryBudgets: _categoryBudgets,
          ),
        ),
      ),
    );
  }
}
