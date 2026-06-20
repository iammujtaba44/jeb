import 'package:dartz/dartz.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/core/error/failures.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/plans/data/datasources/plans_local_datasource.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_payment.dart';
import 'package:jeb/features/plans/domain/repositories/plans_repository.dart';

final class PlansRepositoryImpl implements PlansRepository {
  const PlansRepositoryImpl(this._local);

  final PlansLocalDataSource _local;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  ResultFuture<List<Plan>> getPlans() => _guard(_local.getPlans);

  @override
  ResultVoid savePlan(Plan plan) => _guard(() => _local.upsertPlan(plan));

  @override
  ResultVoid deletePlan(String id) => _guard(() => _local.deletePlan(id));

  @override
  ResultFuture<Map<String, double>> paidByPlan() => _guard(_local.paidByPlan);

  @override
  ResultFuture<List<PlanPayment>> getPayments(String planId) =>
      _guard(() => _local.getPayments(planId));

  @override
  ResultVoid addPayment(PlanPayment payment) =>
      _guard(() => _local.upsertPayment(payment));

  @override
  ResultVoid deletePayment(String id) => _guard(() => _local.deletePayment(id));
}
