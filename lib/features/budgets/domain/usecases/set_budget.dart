import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/repositories/budget_repository.dart';

final class SetBudget extends UseCase<void, Budget> {
  const SetBudget(this._repository);

  final BudgetRepository _repository;

  @override
  ResultVoid call(Budget params) => _repository.setBudget(params);
}
