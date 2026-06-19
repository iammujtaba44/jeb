part of 'insights_cubit.dart';

/// One month's totals (home currency) plus its per-category expense breakdown.
class MonthStat extends Equatable {
  const MonthStat({
    required this.month,
    required this.expense,
    required this.income,
    this.byCategory = const <String, double>{},
  });

  final DateTime month;
  final double expense;
  final double income;
  final Map<String, double> byCategory;

  @override
  List<Object?> get props => <Object?>[month, expense, income, byCategory];
}

/// A category's spend (category may be null if it was deleted).
class CategorySpend extends Equatable {
  const CategorySpend({required this.category, required this.amount});

  final Category? category;
  final double amount;

  String get name => category?.name ?? 'Uncategorized';

  @override
  List<Object?> get props => <Object?>[category, amount];
}

/// A month's spend measured against the (current) monthly budget, with the
/// categories that drove it — answering "was it over, and why".
class MonthBudgetCheck extends Equatable {
  const MonthBudgetCheck({
    required this.month,
    required this.expense,
    required this.budget,
    required this.drivers,
  });

  final DateTime month;
  final double expense;
  final double? budget;
  final List<CategorySpend> drivers;

  bool get hasBudget => budget != null;
  bool get exceeded => budget != null && expense > budget!;
  double get over => exceeded ? expense - budget! : 0;
  double get remaining => budget == null ? 0 : budget! - expense;

  @override
  List<Object?> get props => <Object?>[month, expense, budget, drivers];
}

final class InsightsState extends Equatable {
  const InsightsState({
    this.isLoading = true,
    this.rangeMonths = 6,
    this.currency = '',
    this.months = const <MonthStat>[],
    this.topCategories = const <CategorySpend>[],
    this.checks = const <MonthBudgetCheck>[],
    this.totalIncome = 0,
    this.totalSpending = 0,
    this.budgetPerMonth,
  });

  final bool isLoading;
  final int rangeMonths;
  final String currency;

  /// Chronological (oldest → current).
  final List<MonthStat> months;
  final List<CategorySpend> topCategories;
  final List<MonthBudgetCheck> checks;

  final double totalIncome;
  final double totalSpending;

  /// Effective monthly budget (overall, or summed category limits), or null.
  final double? budgetPerMonth;

  double get totalSavings => totalIncome - totalSpending;

  /// Total budget allocated across the range, or null if no budget is set.
  double? get totalBudget =>
      budgetPerMonth == null ? null : budgetPerMonth! * rangeMonths;

  double get maxMonthlyExpense => months.fold<double>(
        0,
        (double m, MonthStat s) => s.expense > m ? s.expense : m,
      );

  int get monthsOverBudget =>
      checks.where((MonthBudgetCheck c) => c.exceeded).length;

  @override
  List<Object?> get props => <Object?>[
        isLoading,
        rangeMonths,
        currency,
        months,
        topCategories,
        checks,
        totalIncome,
        totalSpending,
        budgetPerMonth,
      ];
}
