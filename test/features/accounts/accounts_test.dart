import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/accounts/data/models/account_model.dart';
import 'package:jeb/features/accounts/data/models/transfer_model.dart';
import 'package:jeb/features/accounts/domain/entities/account.dart';
import 'package:jeb/features/accounts/domain/entities/account_balance.dart';
import 'package:jeb/features/accounts/domain/entities/account_type.dart';
import 'package:jeb/features/accounts/domain/entities/transfer.dart';

void main() {
  group('AccountBalance.compute', () {
    final Account a = Account(
      id: 'a',
      name: 'Cash',
      type: AccountType.cash,
      currencyCode: 'PKR',
      openingBalance: 1000,
    );
    final Account b = Account(
      id: 'b',
      name: 'Bank',
      type: AccountType.bank,
      currencyCode: 'PKR',
    );

    test('opening + income − expense + transfers in/out', () {
      final Map<String, double> result = AccountBalance.compute(
        accounts: <Account>[a, b],
        incomeByAccount: <String, double>{'a': 500},
        expenseByAccount: <String, double>{'a': 200},
        transfers: <Transfer>[
          Transfer(
            id: 't1',
            fromAccountId: 'a',
            toAccountId: 'b',
            amount: 300,
            date: DateTime(2026, 6, 1),
          ),
        ],
      );
      expect(result['a'], 1000 + 500 - 200 - 300); // 1000
      expect(result['b'], 300); // same currency → no conversion
    });

    test('ignores transfers that reference a missing account', () {
      final Map<String, double> result = AccountBalance.compute(
        accounts: <Account>[a],
        incomeByAccount: const <String, double>{},
        expenseByAccount: const <String, double>{},
        transfers: <Transfer>[
          Transfer(
            id: 't2',
            fromAccountId: 'a',
            toAccountId: 'gone',
            amount: 100,
            date: DateTime(2026, 6, 1),
          ),
        ],
      );
      // 'a' still loses the money; the missing destination is skipped.
      expect(result['a'], 900);
      expect(result.containsKey('gone'), isFalse);
    });

    test('an account with no activity keeps its opening balance', () {
      final Map<String, double> result = AccountBalance.compute(
        accounts: <Account>[a, b],
        incomeByAccount: const <String, double>{},
        expenseByAccount: const <String, double>{},
        transfers: const <Transfer>[],
      );
      expect(result['a'], 1000);
      expect(result['b'], 0);
    });
  });

  group('models round-trip through the map', () {
    test('AccountModel', () {
      final AccountModel back = AccountModel.fromMap(
        AccountModel(
          id: 'a1',
          name: 'Meezan',
          type: AccountType.bank,
          currencyCode: 'PKR',
          openingBalance: 25000,
          note: 'salary account',
          updatedAt: DateTime(2026, 6, 1),
        ).toMap(),
      );
      expect(back.name, 'Meezan');
      expect(back.type, AccountType.bank);
      expect(back.currencyCode, 'PKR');
      expect(back.openingBalance, 25000);
      expect(back.note, 'salary account');
      expect(back.archived, isFalse);
    });

    test('TransferModel', () {
      final TransferModel back = TransferModel.fromMap(
        TransferModel(
          id: 'tr1',
          fromAccountId: 'a',
          toAccountId: 'b',
          amount: 500,
          date: DateTime(2026, 6, 2),
          note: 'ATM withdrawal',
          updatedAt: DateTime(2026, 6, 2),
        ).toMap(),
      );
      expect(back.fromAccountId, 'a');
      expect(back.toAccountId, 'b');
      expect(back.amount, 500);
      expect(back.note, 'ATM withdrawal');
    });

    test('AccountModel defaults a missing opening balance to zero', () {
      final DataMap map = AccountModel(
        id: 'a2',
        name: 'Wallet',
        type: AccountType.wallet,
        currencyCode: 'USD',
        updatedAt: DateTime(2026, 6, 1),
      ).toMap();
      expect(AccountModel.fromMap(map).openingBalance, 0);
    });
  });
}
