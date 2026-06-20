import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_payment.dart';
import 'package:jeb/features/plans/domain/repositories/plans_repository.dart';

final class GetPlans extends UseCase<List<Plan>, NoParams> {
  const GetPlans(this._repo);
  final PlansRepository _repo;
  @override
  ResultFuture<List<Plan>> call(NoParams params) => _repo.getPlans();
}

final class SavePlan extends UseCase<void, Plan> {
  const SavePlan(this._repo);
  final PlansRepository _repo;
  @override
  ResultVoid call(Plan params) => _repo.savePlan(params);
}

final class DeletePlan extends UseCase<void, String> {
  const DeletePlan(this._repo);
  final PlansRepository _repo;
  @override
  ResultVoid call(String params) => _repo.deletePlan(params);
}

final class PaidByPlan extends UseCase<Map<String, double>, NoParams> {
  const PaidByPlan(this._repo);
  final PlansRepository _repo;
  @override
  ResultFuture<Map<String, double>> call(NoParams params) => _repo.paidByPlan();
}

final class GetPlanPayments extends UseCase<List<PlanPayment>, String> {
  const GetPlanPayments(this._repo);
  final PlansRepository _repo;
  @override
  ResultFuture<List<PlanPayment>> call(String params) =>
      _repo.getPayments(params);
}

final class AddPlanPayment extends UseCase<void, PlanPayment> {
  const AddPlanPayment(this._repo);
  final PlansRepository _repo;
  @override
  ResultVoid call(PlanPayment params) => _repo.addPayment(params);
}

final class DeletePlanPayment extends UseCase<void, String> {
  const DeletePlanPayment(this._repo);
  final PlansRepository _repo;
  @override
  ResultVoid call(String params) => _repo.deletePayment(params);
}
