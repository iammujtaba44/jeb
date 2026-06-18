part of 'budgets_cubit.dart';

final class BudgetsState extends Equatable {
  const BudgetsState({
    this.isLoading = true,
    this.categories = const <Category>[],
    this.overallLimit,
    this.categoryLimits = const <String, double>{},
  });

  final bool isLoading;
  final List<Category> categories;
  final double? overallLimit;
  final Map<String, double> categoryLimits;

  @override
  List<Object?> get props =>
      [isLoading, categories, overallLimit, categoryLimits];
}
