import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/usecases/get_budgets.dart';
import 'package:jeb/features/budgets/domain/usecases/remove_budget.dart';
import 'package:jeb/features/budgets/domain/usecases/set_budget.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/get_transactions_for_month.dart';

part 'budgets_state.dart';

/// Manages the budgets screen: shows each expense category's limit alongside
/// how much has been spent this month (converted to the home currency), plus
/// the overall monthly limit, and persists changes.
class BudgetsCubit extends Cubit<BudgetsState> {
  BudgetsCubit({
    required GetBudgets getBudgets,
    required SetBudget setBudget,
    required RemoveBudget removeBudget,
    required GetCategories getCategories,
    required GetTransactionsForMonth getTransactionsForMonth,
    required GetSettings getSettings,
  })  : _getBudgets = getBudgets,
        _setBudget = setBudget,
        _removeBudget = removeBudget,
        _getCategories = getCategories,
        _getTransactionsForMonth = getTransactionsForMonth,
        _getSettings = getSettings,
        super(const BudgetsState());

  final GetBudgets _getBudgets;
  final SetBudget _setBudget;
  final RemoveBudget _removeBudget;
  final GetCategories _getCategories;
  final GetTransactionsForMonth _getTransactionsForMonth;
  final GetSettings _getSettings;

  Future<void> load() async {
    final DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

    final settingsResult = await _getSettings(const NoParams());
    final String currency = settingsResult.fold(
      (_) => AppSettings.defaults.defaultCurrencyCode,
      (AppSettings s) => s.defaultCurrencyCode,
    );

    final categoriesResult = await _getCategories(const NoParams());
    final budgetsResult = await _getBudgets(const NoParams());
    final transactionsResult = await _getTransactionsForMonth(month);

    final List<Category> expenseCategories = categoriesResult.fold(
      (_) => const <Category>[],
      (List<Category> categories) => categories
          .where((Category c) => c.type == TransactionType.expense)
          .toList(),
    );

    double? overall;
    final Map<String, double> categoryLimits = <String, double>{};
    budgetsResult.fold((_) {}, (List<Budget> budgets) {
      for (final Budget b in budgets) {
        if (b.isOverall) {
          overall = b.limitAmount;
        } else {
          categoryLimits[b.categoryId!] = b.limitAmount;
        }
      }
    });

    // Spend per category + overall this month, converted to the home currency.
    final Map<String, double> categorySpent = <String, double>{};
    double totalSpent = 0;
    transactionsResult.fold((_) {}, (List<Transaction> transactions) {
      for (final Transaction t in transactions) {
        if (t.type != TransactionType.expense) continue;
        final double converted = CurrencyConverter.convert(
          amount: t.amount,
          from: t.currencyCode,
          to: currency,
        );
        categorySpent[t.categoryId] =
            (categorySpent[t.categoryId] ?? 0) + converted;
        totalSpent += converted;
      }
    });

    emit(
      BudgetsState(
        isLoading: false,
        currency: currency,
        categories: expenseCategories,
        overallLimit: overall,
        categoryLimits: categoryLimits,
        categorySpent: categorySpent,
        totalSpent: totalSpent,
      ),
    );
  }

  Future<void> setOverall(double? amount) =>
      _apply(null, amount);

  Future<void> setCategory(String categoryId, double? amount) =>
      _apply(categoryId, amount);

  Future<void> _apply(String? categoryId, double? amount) async {
    if (amount == null || amount <= 0) {
      await _removeBudget(categoryId);
    } else {
      await _setBudget(Budget(categoryId: categoryId, limitAmount: amount));
    }
    await load();
  }
}
