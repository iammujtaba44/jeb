part of 'budgets_cubit.dart';

final class BudgetsState extends Equatable {
  const BudgetsState({
    this.isLoading = true,
    this.currency = '',
    this.month,
    this.categories = const <Category>[],
    this.overallLimit,
    this.categoryLimits = const <String, double>{},
    this.categorySpent = const <String, double>{},
    this.totalSpent = 0,
  });

  final bool isLoading;
  final String currency;

  /// First day of the month the spending figures cover.
  final DateTime? month;

  final List<Category> categories;
  final double? overallLimit;
  final Map<String, double> categoryLimits;

  /// Spend in [month] per category id (home currency).
  final Map<String, double> categorySpent;

  /// Total expense in [month] (home currency).
  final double totalSpent;

  double spentFor(String categoryId) => categorySpent[categoryId] ?? 0;

  bool get isCurrentMonth {
    final DateTime? m = month;
    if (m == null) return true;
    final DateTime now = DateTime.now();
    return m.year == now.year && m.month == now.month;
  }

  @override
  List<Object?> get props => [
        isLoading,
        currency,
        month,
        categories,
        overallLimit,
        categoryLimits,
        categorySpent,
        totalSpent,
      ];
}
