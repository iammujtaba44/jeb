import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/domain/repositories/budget_repository.dart';

final class RemoveBudget extends UseCase<void, String?> {
  const RemoveBudget(this._repository);

  final BudgetRepository _repository;

  @override
  ResultVoid call(String? params) => _repository.removeBudget(params);
}
