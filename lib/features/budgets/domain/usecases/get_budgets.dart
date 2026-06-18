import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/repositories/budget_repository.dart';

final class GetBudgets extends UseCase<List<Budget>, NoParams> {
  const GetBudgets(this._repository);

  final BudgetRepository _repository;

  @override
  ResultFuture<List<Budget>> call(NoParams params) => _repository.getBudgets();
}
