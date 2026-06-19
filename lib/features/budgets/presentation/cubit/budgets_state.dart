part of 'budgets_cubit.dart';

final class BudgetsState extends Equatable {
  const BudgetsState({
    this.isLoading = true,
    this.currency = '',
    this.categories = const <Category>[],
    this.overallLimit,
    this.categoryLimits = const <String, double>{},
    this.categorySpent = const <String, double>{},
    this.totalSpent = 0,
  });

  final bool isLoading;
  final String currency;
  final List<Category> categories;
  final double? overallLimit;
  final Map<String, double> categoryLimits;

  /// Spend this month per category id (home currency).
  final Map<String, double> categorySpent;

  /// Total expense this month (home currency).
  final double totalSpent;

  double spentFor(String categoryId) => categorySpent[categoryId] ?? 0;

  @override
  List<Object?> get props => [
        isLoading,
        currency,
        categories,
        overallLimit,
        categoryLimits,
        categorySpent,
        totalSpent,
      ];
}
