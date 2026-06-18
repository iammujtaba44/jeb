import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/search_criteria.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/search_transactions.dart';

part 'search_state.dart';

/// Drives the search screen: holds the current criteria + results and re-runs
/// the query whenever a filter changes.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required SearchTransactions searchTransactions,
    required GetCategories getCategories,
  })  : _searchTransactions = searchTransactions,
        _getCategories = getCategories,
        super(const SearchState());

  final SearchTransactions _searchTransactions;
  final GetCategories _getCategories;

  Future<void> init() async {
    final result = await _getCategories(const NoParams());
    result.fold(
      (_) {},
      (List<Category> categories) =>
          emit(state.copyWith(categories: categories)),
    );
    await _apply(state.criteria);
  }

  void setQuery(String query) => _apply(state.criteria.copyWith(query: query));

  void setType(TransactionType? type) =>
      _apply(state.criteria.copyWith(type: type));

  void setCategory(String? categoryId) =>
      _apply(state.criteria.copyWith(categoryId: categoryId));

  void setDateRange(DateTime? from, DateTime? to) =>
      _apply(state.criteria.copyWith(from: from, to: to));

  void setAmountRange(double? min, double? max) =>
      _apply(state.criteria.copyWith(minAmount: min, maxAmount: max));

  void clearFilters() =>
      _apply(SearchCriteria(query: state.criteria.query));

  Future<void> refresh() => _apply(state.criteria);

  Future<void> _apply(SearchCriteria criteria) async {
    emit(state.copyWith(criteria: criteria, isLoading: true));
    final result = await _searchTransactions(criteria);
    result.fold(
      (_) => emit(state.copyWith(isLoading: false, results: const <Transaction>[])),
      (List<Transaction> results) =>
          emit(state.copyWith(isLoading: false, results: results)),
    );
  }
}
