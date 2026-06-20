import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';

abstract interface class AccountsRepository {
  ResultFuture<List<Account>> getAccounts();

  /// Archived (hidden) accounts, kept out of [getAccounts] and balances.
  ResultFuture<List<Account>> getArchivedAccounts();
  ResultVoid saveAccount(Account account);
  ResultVoid deleteAccount(String id);

  /// Current balance per account id, each in the account's own currency.
  ResultFuture<Map<String, double>> balances();

  ResultFuture<List<Transfer>> getTransfers();
  ResultVoid saveTransfer(Transfer transfer);
  ResultVoid deleteTransfer(String id);
}
