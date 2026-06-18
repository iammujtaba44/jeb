import 'package:dartz/dartz.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/core/error/failures.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/data/datasources/cloud_sync_datasource.dart';
import 'package:jeb/features/transactions/data/datasources/transaction_local_datasource.dart';
import 'package:jeb/features/transactions/domain/entities/category.dart';
import 'package:jeb/features/transactions/domain/entities/search_criteria.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/repositories/transaction_repository.dart';

/// Coordinates the local store (source of truth) and cloud sync, mapping
/// low-level exceptions to domain [Failure]s.
final class TransactionRepositoryImpl implements TransactionRepository {
  const TransactionRepositoryImpl({
    required TransactionLocalDataSource localDataSource,
    required CloudSyncDataSource cloudSyncDataSource,
  })  : _local = localDataSource,
        _cloud = cloudSyncDataSource;

  final TransactionLocalDataSource _local;
  final CloudSyncDataSource _cloud;

  @override
  ResultFuture<List<Transaction>> getTransactionsForMonth(
    DateTime month,
  ) async {
    try {
      final result = await _local.getTransactionsForMonth(month);
      return Right(result);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultFuture<List<Transaction>> searchTransactions(
    SearchCriteria criteria,
  ) async {
    try {
      final result = await _local.searchTransactions(criteria);
      return Right(result);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultFuture<Transaction> addTransaction(Transaction transaction) async {
    try {
      final result = await _local.upsertTransaction(transaction);
      return Right(result);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid deleteTransaction(String id) async {
    try {
      await _local.softDeleteTransaction(id);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultFuture<List<Category>> getCategories() async {
    try {
      final result = await _local.getCategories();
      return Right(result);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid saveCategory(Category category) async {
    try {
      await _local.upsertCategory(category);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid deleteCategory(String id) async {
    try {
      await _local.softDeleteCategory(id);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid sync() async {
    try {
      await _cloud.sync();
      return const Right(null);
    } on SyncException catch (error) {
      return Left(SyncFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
