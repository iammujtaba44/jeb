import 'package:dartz/dartz.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/core/error/failures.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/budgets/data/datasources/budget_local_datasource.dart';
import 'package:jeb/features/budgets/domain/entities/budget.dart';
import 'package:jeb/features/budgets/domain/repositories/budget_repository.dart';

final class BudgetRepositoryImpl implements BudgetRepository {
  const BudgetRepositoryImpl(this._localDataSource);

  final BudgetLocalDataSource _localDataSource;

  @override
  ResultFuture<List<Budget>> getBudgets() async {
    try {
      return Right(await _localDataSource.getBudgets());
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid setBudget(Budget budget) async {
    try {
      await _localDataSource.upsertBudget(budget);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid removeBudget(String? categoryId) async {
    try {
      await _localDataSource.removeBudget(categoryId);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
