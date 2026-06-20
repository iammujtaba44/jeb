import 'package:dartz/dartz.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/core/error/failures.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/accounts/data/datasources/accounts_local_datasource.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
import 'package:jeb/features/accounts/domain/repositories/accounts_repository.dart';

final class AccountsRepositoryImpl implements AccountsRepository {
  const AccountsRepositoryImpl(this._local);

  final AccountsLocalDataSource _local;

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
  ResultFuture<List<Account>> getAccounts() => _guard(_local.getAccounts);

  @override
  ResultFuture<List<Account>> getArchivedAccounts() =>
      _guard(_local.getArchivedAccounts);

  @override
  ResultVoid saveAccount(Account account) =>
      _guard(() => _local.upsertAccount(account));

  @override
  ResultVoid deleteAccount(String id) =>
      _guard(() => _local.deleteAccount(id));

  @override
  ResultFuture<Map<String, double>> balances() => _guard(_local.balances);

  @override
  ResultFuture<List<Transfer>> getTransfers() => _guard(_local.getTransfers);

  @override
  ResultVoid saveTransfer(Transfer transfer) =>
      _guard(() => _local.upsertTransfer(transfer));

  @override
  ResultVoid deleteTransfer(String id) =>
      _guard(() => _local.deleteTransfer(id));
}
