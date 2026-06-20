import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
import 'package:jeb/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';

final class GetAccounts extends UseCase<List<Account>, NoParams> {
  const GetAccounts(this._repo);
  final AccountsRepository _repo;
  @override
  ResultFuture<List<Account>> call(NoParams params) => _repo.getAccounts();
}

final class GetArchivedAccounts extends UseCase<List<Account>, NoParams> {
  const GetArchivedAccounts(this._repo);
  final AccountsRepository _repo;
  @override
  ResultFuture<List<Account>> call(NoParams params) =>
      _repo.getArchivedAccounts();
}

final class SaveAccount extends UseCase<void, Account> {
  const SaveAccount(this._repo);
  final AccountsRepository _repo;
  @override
  ResultVoid call(Account params) => _repo.saveAccount(params);
}

final class DeleteAccount extends UseCase<void, String> {
  const DeleteAccount(this._repo);
  final AccountsRepository _repo;
  @override
  ResultVoid call(String params) => _repo.deleteAccount(params);
}

final class GetAccountBalances extends UseCase<Map<String, double>, NoParams> {
  const GetAccountBalances(this._repo);
  final AccountsRepository _repo;
  @override
  ResultFuture<Map<String, double>> call(NoParams params) => _repo.balances();
}

final class GetAccountTransactions extends UseCase<List<Transaction>, String> {
  const GetAccountTransactions(this._repo);
  final AccountsRepository _repo;
  @override
  ResultFuture<List<Transaction>> call(String params) =>
      _repo.accountTransactions(params);
}

final class GetTransfers extends UseCase<List<Transfer>, NoParams> {
  const GetTransfers(this._repo);
  final AccountsRepository _repo;
  @override
  ResultFuture<List<Transfer>> call(NoParams params) => _repo.getTransfers();
}

final class SaveTransfer extends UseCase<void, Transfer> {
  const SaveTransfer(this._repo);
  final AccountsRepository _repo;
  @override
  ResultVoid call(Transfer params) => _repo.saveTransfer(params);
}

final class DeleteTransfer extends UseCase<void, String> {
  const DeleteTransfer(this._repo);
  final AccountsRepository _repo;
  @override
  ResultVoid call(String params) => _repo.deleteTransfer(params);
}
