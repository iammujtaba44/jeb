part of 'search_cubit.dart';

final class SearchState extends Equatable {
  const SearchState({
    this.criteria = const SearchCriteria(),
    this.results = const <Transaction>[],
    this.categories = const <Category>[],
    this.isLoading = false,
  });

  final SearchCriteria criteria;
  final List<Transaction> results;
  final List<Category> categories;
  final bool isLoading;

  Map<String, Category> get categoriesById =>
      <String, Category>{for (final Category c in categories) c.id: c};

  SearchState copyWith({
    SearchCriteria? criteria,
    List<Transaction>? results,
    List<Category>? categories,
    bool? isLoading,
  }) {
    return SearchState(
      criteria: criteria ?? this.criteria,
      results: results ?? this.results,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [criteria, results, categories, isLoading];
}
