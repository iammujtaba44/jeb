import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/usecases/get_budgets.dart';
import 'package:jeb/features/budgets/domain/usecases/remove_budget.dart';
import 'package:jeb/features/budgets/domain/usecases/set_budget.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/domain/usecases/get_categories.dart';

part 'budgets_state.dart';

/// Manages the budget-setup screen: lists expense categories with their limits
/// and the overall monthly limit, and persists changes.
class BudgetsCubit extends Cubit<BudgetsState> {
  BudgetsCubit({
    required GetBudgets getBudgets,
    required SetBudget setBudget,
    required RemoveBudget removeBudget,
    required GetCategories getCategories,
  })  : _getBudgets = getBudgets,
        _setBudget = setBudget,
        _removeBudget = removeBudget,
        _getCategories = getCategories,
        super(const BudgetsState());

  final GetBudgets _getBudgets;
  final SetBudget _setBudget;
  final RemoveBudget _removeBudget;
  final GetCategories _getCategories;

  Future<void> load() async {
    final categoriesResult = await _getCategories(const NoParams());
    final budgetsResult = await _getBudgets(const NoParams());

    final List<Category> expenseCategories = categoriesResult.fold(
      (_) => const <Category>[],
      (List<Category> categories) => categories
          .where((Category c) => c.type == TransactionType.expense)
          .toList(),
    );

    double? overall;
    final Map<String, double> categoryLimits = <String, double>{};
    budgetsResult.fold((_) {}, (List<Budget> budgets) {
      for (final Budget b in budgets) {
        if (b.isOverall) {
          overall = b.limitAmount;
        } else {
          categoryLimits[b.categoryId!] = b.limitAmount;
        }
      }
    });

    emit(
      BudgetsState(
        isLoading: false,
        categories: expenseCategories,
        overallLimit: overall,
        categoryLimits: categoryLimits,
      ),
    );
  }

  Future<void> setOverall(double? amount) =>
      _apply(null, amount);

  Future<void> setCategory(String categoryId, double? amount) =>
      _apply(categoryId, amount);

  Future<void> _apply(String? categoryId, double? amount) async {
    if (amount == null || amount <= 0) {
      await _removeBudget(categoryId);
    } else {
      await _setBudget(Budget(categoryId: categoryId, limitAmount: amount));
    }
    await load();
  }
}
