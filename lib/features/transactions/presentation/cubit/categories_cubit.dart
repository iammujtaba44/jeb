import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/delete_category.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';
import 'package:jeb/features/transactions/domain/usecases/save_category.dart';

part 'categories_state.dart';

/// Manages the category-management screen: list, create, edit, delete.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit({
    required GetCategories getCategories,
    required SaveCategory saveCategory,
    required DeleteCategory deleteCategory,
  })  : _getCategories = getCategories,
        _saveCategory = saveCategory,
        _deleteCategory = deleteCategory,
        super(const CategoriesState());

  final GetCategories _getCategories;
  final SaveCategory _saveCategory;
  final DeleteCategory _deleteCategory;

  Future<void> load() async {
    final result = await _getCategories(const NoParams());
    result.fold(
      (_) => emit(const CategoriesState(isLoading: false)),
      (List<Category> categories) =>
          emit(CategoriesState(isLoading: false, categories: categories)),
    );
  }

  Future<void> save(Category category) async {
    await _saveCategory(category);
    await load();
  }

  Future<void> delete(String id) async {
    await _deleteCategory(id);
    await load();
  }
}
