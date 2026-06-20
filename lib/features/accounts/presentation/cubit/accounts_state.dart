part of 'accounts_cubit.dart';

final class AccountsState extends Equatable {
  const AccountsState({
    this.isLoading = true,
    this.accounts = const <Account>[],
    this.archived = const <Account>[],
    this.balances = const <String, double>{},
    this.transfers = const <Transfer>[],
    this.currency = '',
    this.totalNet = 0,
  });

  final bool isLoading;
  final List<Account> accounts;

  /// Archived accounts, hidden from totals but listed so they can be restored.
  final List<Account> archived;

  /// Balance per account id, in that account's own currency.
  final Map<String, double> balances;
  final List<Transfer> transfers;

  /// Home currency, and the net position across all accounts (converted to it).
  final String currency;
  final double totalNet;

  bool get isEmpty => accounts.isEmpty && archived.isEmpty;
  bool get canTransfer => accounts.length >= 2;

  double balanceFor(Account account) =>
      balances[account.id] ?? account.openingBalance;

  Account? accountById(String id) {
    for (final Account a in <Account>[...accounts, ...archived]) {
      if (a.id == id) return a;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
        isLoading,
        accounts,
        archived,
        balances,
        transfers,
        currency,
        totalNet,
      ];
}
