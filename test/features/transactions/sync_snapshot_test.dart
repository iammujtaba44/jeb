import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/budgets/data/models/budget_model.dart';
import 'package:jeb/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:jeb/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';
import 'package:jeb/features/transactions/data/sync/sync_snapshot.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

void main() {
  group('SyncSnapshot', () {
    test('round-trips budgets and recurring rules through JSON', () {
      final SyncSnapshot snap = SyncSnapshot(
        transactions: <TransactionModel>[
          TransactionModel(
            id: 't1',
            amount: 10,
            currencyCode: 'EUR',
            categoryId: 'food',
            date: DateTime(2026, 6, 1),
            type: TransactionType.expense,
            updatedAt: DateTime(2026, 6, 1),
          ),
        ],
        categories: const [],
        budgets: <BudgetModel>[
          BudgetModel(
            categoryId: 'food',
            limitAmount: 200,
            updatedAt: DateTime(2026, 6, 1),
          ),
          BudgetModel(
            categoryId: 'rent',
            limitAmount: 0,
            updatedAt: DateTime(2026, 6, 2),
            isDeleted: true, // tombstone propagates
          ),
        ],
        recurring: <RecurringTransactionModel>[
          RecurringTransactionModel(
            id: 'r1',
            amount: 9.99,
            currencyCode: 'EUR',
            categoryId: 'subs',
            type: TransactionType.expense,
            frequency: RecurrenceFrequency.monthly,
            startDate: DateTime(2026, 1, 1),
            nextDueDate: DateTime(2026, 7, 1),
            updatedAt: DateTime(2026, 6, 1),
          ),
        ],
      );

      final SyncSnapshot back = SyncSnapshot.fromJson(snap.toJson());

      expect(back.budgets, hasLength(2));
      expect(back.budgets.first.categoryId, 'food');
      expect(back.budgets.first.limitAmount, 200);
      expect(back.budgets[1].isDeleted, isTrue);
      expect(back.recurring, hasLength(1));
      expect(back.recurring.first.id, 'r1');
      expect(back.recurring.first.frequency, RecurrenceFrequency.monthly);
    });

    test('parses a legacy v1 snapshot with no budgets/recurring keys', () {
      const String legacy =
          '{"version":1,"transactions":[],"categories":[]}';
      final SyncSnapshot back = SyncSnapshot.fromJson(legacy);
      expect(back.budgets, isEmpty);
      expect(back.recurring, isEmpty);
    });
  });
}
