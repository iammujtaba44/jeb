import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';
import 'package:jeb/features/accounts/domain/usecases/accounts_usecases.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';

part 'accounts_state.dart';

/// Drives the Accounts screen: lists wallets with their live balances, the
/// total cash position in the home currency, and recent transfers.
class AccountsCubit extends Cubit<AccountsState> {
  AccountsCubit({
    required GetAccounts getAccounts,
    required SaveAccount saveAccount,
    required DeleteAccount deleteAccount,
    required GetAccountBalances getAccountBalances,
    required GetTransfers getTransfers,
    required SaveTransfer saveTransfer,
    required DeleteTransfer deleteTransfer,
    required GetSettings getSettings,
  })  : _getAccounts = getAccounts,
        _saveAccount = saveAccount,
        _deleteAccount = deleteAccount,
        _getAccountBalances = getAccountBalances,
        _getTransfers = getTransfers,
        _saveTransfer = saveTransfer,
        _deleteTransfer = deleteTransfer,
        _getSettings = getSettings,
        super(const AccountsState());

  final GetAccounts _getAccounts;
  final SaveAccount _saveAccount;
  final DeleteAccount _deleteAccount;
  final GetAccountBalances _getAccountBalances;
  final GetTransfers _getTransfers;
  final SaveTransfer _saveTransfer;
  final DeleteTransfer _deleteTransfer;
  final GetSettings _getSettings;

  Future<void> load() async {
    final settingsResult = await _getSettings(const NoParams());
    final accountsResult = await _getAccounts(const NoParams());
    final balancesResult = await _getAccountBalances(const NoParams());
    final transfersResult = await _getTransfers(const NoParams());
    if (isClosed) return;

    final String currency = settingsResult.fold(
      (_) => AppSettings.defaults.defaultCurrencyCode,
      (AppSettings s) => s.defaultCurrencyCode,
    );
    final List<Account> accounts =
        accountsResult.fold((_) => const <Account>[], (List<Account> a) => a);
    final Map<String, double> balances = balancesResult.fold(
      (_) => const <String, double>{},
      (Map<String, double> b) => b,
    );
    final List<Transfer> transfers = transfersResult.fold(
      (_) => const <Transfer>[],
      (List<Transfer> t) => t,
    );

    // Net cash position across every account, in the home currency.
    double total = 0;
    for (final Account a in accounts) {
      total += CurrencyConverter.convert(
        amount: balances[a.id] ?? a.openingBalance,
        from: a.currencyCode,
        to: currency,
      );
    }

    emit(
      AccountsState(
        isLoading: false,
        accounts: accounts,
        balances: balances,
        transfers: transfers,
        currency: currency,
        totalNet: total,
      ),
    );
  }

  Future<void> saveAccount(Account account) async {
    await _saveAccount(account);
    await load();
  }

  Future<void> deleteAccount(String id) async {
    await _deleteAccount(id);
    await load();
  }

  Future<void> addTransfer(Transfer transfer) async {
    await _saveTransfer(transfer);
    await load();
  }

  Future<void> deleteTransfer(String id) async {
    await _deleteTransfer(id);
    await load();
  }
}
