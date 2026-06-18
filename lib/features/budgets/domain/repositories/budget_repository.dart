import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';

abstract interface class BudgetRepository {
  ResultFuture<List<Budget>> getBudgets();
  ResultVoid setBudget(Budget budget);

  /// Removes a budget. Pass null to remove the overall budget.
  ResultVoid removeBudget(String? categoryId);
}
