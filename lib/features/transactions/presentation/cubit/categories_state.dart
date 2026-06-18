part of 'categories_cubit.dart';

final class CategoriesState extends Equatable {
  const CategoriesState({
    this.isLoading = true,
    this.categories = const <Category>[],
  });

  final bool isLoading;
  final List<Category> categories;

  List<Category> get expenseCategories => categories
      .where((Category c) => c.type == TransactionType.expense)
      .toList();

  List<Category> get incomeCategories =>
      categories.where((Category c) => c.type == TransactionType.income).toList();

  @override
  List<Object?> get props => [isLoading, categories];
}
