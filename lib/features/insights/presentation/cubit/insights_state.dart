part of 'insights_cubit.dart';

/// One month's expense + income totals (home currency).
class MonthStat extends Equatable {
  const MonthStat({
    required this.month,
    required this.expense,
    required this.income,
  });

  final DateTime month;
  final double expense;
  final double income;

  @override
  List<Object?> get props => <Object?>[month, expense, income];
}

/// A category's spend this month (category may be null if it was deleted).
class CategorySpend extends Equatable {
  const CategorySpend({required this.category, required this.amount});

  final Category? category;
  final double amount;

  @override
  List<Object?> get props => <Object?>[category, amount];
}

final class InsightsState extends Equatable {
  const InsightsState({
    this.isLoading = true,
    this.currency = '',
    this.months = const <MonthStat>[],
    this.topCategories = const <CategorySpend>[],
    this.avgPerDay = 0,
  });

  final bool isLoading;
  final String currency;

  /// Chronological (oldest → current).
  final List<MonthStat> months;
  final List<CategorySpend> topCategories;
  final double avgPerDay;

  double get currentExpense => months.isEmpty ? 0 : months.last.expense;
  double get previousExpense =>
      months.length < 2 ? 0 : months[months.length - 2].expense;

  /// Month-over-month change as a fraction, or null when there's no prior data.
  double? get momChange {
    if (previousExpense <= 0) return null;
    return (currentExpense - previousExpense) / previousExpense;
  }

  /// The largest monthly expense in the window (for scaling the chart).
  double get maxMonthlyExpense => months.fold<double>(
        0,
        (double m, MonthStat s) => s.expense > m ? s.expense : m,
      );

  @override
  List<Object?> get props =>
      <Object?>[isLoading, currency, months, topCategories, avgPerDay];
}
