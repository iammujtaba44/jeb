import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/get_transactions_for_month.dart';

part 'insights_state.dart';

/// Aggregates the last [_monthsBack] months of spending into chart-ready stats,
/// all converted to the home currency.
class InsightsCubit extends Cubit<InsightsState> {
  InsightsCubit({
    required GetTransactionsForMonth getTransactionsForMonth,
    required GetCategories getCategories,
    required GetSettings getSettings,
  })  : _getTransactionsForMonth = getTransactionsForMonth,
        _getCategories = getCategories,
        _getSettings = getSettings,
        super(const InsightsState());

  final GetTransactionsForMonth _getTransactionsForMonth;
  final GetCategories _getCategories;
  final GetSettings _getSettings;

  static const int _monthsBack = 6;
  static const int _topCategoryCount = 6;

  Future<void> load() async {
    final DateTime now = DateTime.now();

    final settingsResult = await _getSettings(const NoParams());
    final String currency = settingsResult.fold(
      (_) => AppSettings.defaults.defaultCurrencyCode,
      (AppSettings s) => s.defaultCurrencyCode,
    );

    final categoriesResult = await _getCategories(const NoParams());
    final Map<String, Category> categoriesById = categoriesResult.fold(
      (_) => const <String, Category>{},
      (List<Category> c) => <String, Category>{for (final Category x in c) x.id: x},
    );

    double convert(Transaction t) => CurrencyConverter.convert(
          amount: t.amount,
          from: t.currencyCode,
          to: currency,
        );

    final List<MonthStat> months = <MonthStat>[];
    final Map<String, double> currentByCategory = <String, double>{};

    for (int offset = _monthsBack - 1; offset >= 0; offset--) {
      final DateTime month = DateTime(now.year, now.month - offset);
      final result = await _getTransactionsForMonth(month);
      final List<Transaction> transactions = result.fold(
        (_) => const <Transaction>[],
        (List<Transaction> t) => t,
      );

      double expense = 0;
      double income = 0;
      for (final Transaction t in transactions) {
        final double value = convert(t);
        if (t.type == TransactionType.expense) {
          expense += value;
          if (offset == 0) {
            currentByCategory[t.categoryId] =
                (currentByCategory[t.categoryId] ?? 0) + value;
          }
        } else {
          income += value;
        }
      }
      months.add(MonthStat(month: month, expense: expense, income: income));
    }

    final List<CategorySpend> topCategories = currentByCategory.entries
        .map((MapEntry<String, double> e) => CategorySpend(
              category: categoriesById[e.key],
              amount: e.value,
            ))
        .toList()
      ..sort((CategorySpend a, CategorySpend b) =>
          b.amount.compareTo(a.amount));

    final double currentExpense = months.isEmpty ? 0 : months.last.expense;
    final double avgPerDay = now.day == 0 ? 0 : currentExpense / now.day;

    emit(
      InsightsState(
        isLoading: false,
        currency: currency,
        months: months,
        topCategories: topCategories.take(_topCategoryCount).toList(),
        avgPerDay: avgPerDay,
      ),
    );
  }
}
