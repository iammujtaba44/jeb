import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_payment.dart';

abstract interface class PlansRepository {
  ResultFuture<List<Plan>> getPlans();
  ResultVoid savePlan(Plan plan);
  ResultVoid deletePlan(String id);

  /// Total paid per plan id, summed across that plan's payments.
  ResultFuture<Map<String, double>> paidByPlan();

  ResultFuture<List<PlanPayment>> getPayments(String planId);
  ResultVoid addPayment(PlanPayment payment);
  ResultVoid deletePayment(String id);
}
