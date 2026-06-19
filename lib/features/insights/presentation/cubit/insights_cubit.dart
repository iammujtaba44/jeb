import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/usecases/get_budgets.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/get_transactions_for_month.dart';

part 'insights_state.dart';

/// Aggregates a selectable range of months into chart- and summary-ready stats,
/// all converted to the home currency, plus a per-month budget check.
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit({
    required GetTransactionsForMonth getTransactionsForMonth,
    required GetCategories getCategories,
    required GetBudgets getBudgets,
    required GetSettings getSettings,
  })  : _getTransactionsForMonth = getTransactionsForMonth,
        _getCategories = getCategories,
        _getBudgets = getBudgets,
        _getSettings = getSettings,
        super(const InsightsState());

  final GetTransactionsForMonth _getTransactionsForMonth;
  final GetCategories _getCategories;
  final GetBudgets _getBudgets;
  final GetSettings _getSettings;

  /// Selectable range lengths, in months.
  static const List<int> ranges = <int>[3, 6, 12];
  static const int _topCategoryCount = 6;
  static const int _driverCount = 3;

  Future<void> load() => _load(state.rangeMonths);

  Future<void> setRange(int months) {
    if (months == state.rangeMonths && !state.isLoading) return Future<void>.value();
    emit(InsightsState(rangeMonths: months, currency: state.currency));
    return _load(months);
  }

  Future<void> _load(int rangeMonths) async {
    final DateTime now = DateTime.now();

    final settingsResult = await _getSettings(const NoParams());
    final String currency = settingsResult.fold(
      (_) => AppSettings.defaults.defaultCurrencyCode,
      (AppSettings s) => s.defaultCurrencyCode,
    );

    final categoriesResult = await _getCategories(const NoParams());
    final Map<String, Category> categoriesById = categoriesResult.fold(
      (_) => const <String, Category>{},
      (List<Category> c) =>
          <String, Category>{for (final Category x in c) x.id: x},
    );

    // Current budget configuration (applied to every month in the range).
    double? overall;
    final Map<String, double> categoryLimits = <String, double>{};
    final budgetsResult = await _getBudgets(const NoParams());
    budgetsResult.fold((_) {}, (List<Budget> budgets) {
      for (final Budget b in budgets) {
        if (b.isOverall) {
          overall = b.limitAmount;
        } else {
          categoryLimits[b.categoryId!] = b.limitAmount;
        }
      }
    });
    final double categoryLimitSum =
        categoryLimits.values.fold(0, (double s, double v) => s + v);
    final double? budgetPerMonth =
        overall ?? (categoryLimitSum > 0 ? categoryLimitSum : null);

    double convert(Transaction t) => CurrencyConverter.convert(
          amount: t.amount,
          from: t.currencyCode,
          to: currency,
        );

    final List<MonthStat> months = <MonthStat>[];
    final Map<String, double> rangeByCategory = <String, double>{};
    double totalIncome = 0;
    double totalSpending = 0;

    for (int offset = rangeMonths - 1; offset >= 0; offset--) {
      final DateTime month = DateTime(now.year, now.month - offset);
      final result = await _getTransactionsForMonth(month);
      final List<Transaction> transactions = result.fold(
        (_) => const <Transaction>[],
        (List<Transaction> t) => t,
      );

      double expense = 0;
      double income = 0;
      final Map<String, double> byCategory = <String, double>{};
      for (final Transaction t in transactions) {
        final double value = convert(t);
        if (t.type == TransactionType.expense) {
          expense += value;
          byCategory[t.categoryId] = (byCategory[t.categoryId] ?? 0) + value;
          rangeByCategory[t.categoryId] =
              (rangeByCategory[t.categoryId] ?? 0) + value;
        } else {
          income += value;
        }
      }
      totalSpending += expense;
      totalIncome += income;
      months.add(MonthStat(
        month: month,
        expense: expense,
        income: income,
        byCategory: byCategory,
      ));
    }

    CategorySpend toSpend(MapEntry<String, double> e) =>
        CategorySpend(category: categoriesById[e.key], amount: e.value);

    final List<CategorySpend> topCategories = (rangeByCategory.entries
            .map(toSpend)
            .toList()
          ..sort((CategorySpend a, CategorySpend b) =>
              b.amount.compareTo(a.amount)))
        .take(_topCategoryCount)
        .toList();

    // Per-month budget check with the categories that drove the spend.
    final List<MonthBudgetCheck> checks = <MonthBudgetCheck>[];
    for (final MonthStat m in months) {
      final List<CategorySpend> drivers = (m.byCategory.entries
              .map(toSpend)
              .toList()
            ..sort((CategorySpend a, CategorySpend b) =>
                b.amount.compareTo(a.amount)))
          .take(_driverCount)
          .toList();
      checks.add(MonthBudgetCheck(
        month: m.month,
        expense: m.expense,
        budget: budgetPerMonth,
        drivers: drivers,
      ));
    }

    emit(
      InsightsState(
        isLoading: false,
        rangeMonths: rangeMonths,
        currency: currency,
        months: months,
        topCategories: topCategories,
        checks: checks,
        totalIncome: totalIncome,
        totalSpending: totalSpending,
        budgetPerMonth: budgetPerMonth,
      ),
    );
  }
}
