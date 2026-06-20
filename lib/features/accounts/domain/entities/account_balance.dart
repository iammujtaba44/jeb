import 'package:jeb/core/utils/currency_converter.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';

/// Pure balance maths, kept free of the database so it can be unit-tested.
abstract final class AccountBalance {
  const AccountBalance._();

  /// Current balance per account id, each in that account's own currency:
  /// opening balance + income − expense + transfers in − transfers out.
  ///
  /// [incomeByAccount] / [expenseByAccount] are the summed transaction amounts
  /// per account id (already filtered to non-deleted, assigned transactions).
  /// Transfer amounts are in the source account's currency and converted to the
  /// destination's currency on the way in.
  static Map<String, double> compute({
    required List<Account> accounts,
    required Map<String, double> incomeByAccount,
    required Map<String, double> expenseByAccount,
    required List<Transfer> transfers,
  }) {
    final Map<String, Account> byId = <String, Account>{
      for (final Account a in accounts) a.id: a,
    };
    final Map<String, double> result = <String, double>{
      for (final Account a in accounts) a.id: a.openingBalance,
    };

    incomeByAccount.forEach((String id, double v) {
      if (result.containsKey(id)) result[id] = result[id]! + v;
    });
    expenseByAccount.forEach((String id, double v) {
      if (result.containsKey(id)) result[id] = result[id]! - v;
    });

    for (final Transfer t in transfers) {
      final Account? from = byId[t.fromAccountId];
      final Account? to = byId[t.toAccountId];
      if (from != null) result[from.id] = result[from.id]! - t.amount;
      if (to != null) {
        result[to.id] = result[to.id]! +
            CurrencyConverter.convert(
              amount: t.amount,
              from: from?.currencyCode ?? to.currencyCode,
              to: to.currencyCode,
            );
      }
    }

    return result;
  }
}
