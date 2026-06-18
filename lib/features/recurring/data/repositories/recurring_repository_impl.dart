import 'package:dartz/dartz.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/core/error/failures.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/recurring/data/datasources/recurring_local_datasource.dart';
import 'package:jeb/features/recurring/domain/entities/recurring_transaction.dart';
import 'package:jeb/features/recurring/domain/repositories/recurring_repository.dart';

final class RecurringRepositoryImpl implements RecurringRepository {
  const RecurringRepositoryImpl(this._localDataSource);

  final RecurringLocalDataSource _localDataSource;

  @override
  ResultFuture<List<RecurringTransaction>> getRecurringTransactions() async {
    try {
      return Right(await _localDataSource.getRecurringTransactions());
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid saveRecurringTransaction(RecurringTransaction rule) async {
    try {
      await _localDataSource.upsertRecurringTransaction(rule);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid deleteRecurringTransaction(String id) async {
    try {
      await _localDataSource.deleteRecurringTransaction(id);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultFuture<int> materializeDue(DateTime asOf) async {
    try {
      return Right(await _localDataSource.materializeDue(asOf));
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
