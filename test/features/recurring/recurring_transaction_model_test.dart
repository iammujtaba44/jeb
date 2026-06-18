import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/recurring/data/models/recurring_transaction_model.dart';
import 'package:jeb/features/recurring/domain/entities/recurrence_frequency.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

void main() {
  group('RecurringTransactionModel', () {
    final RecurringTransactionModel withEnd = RecurringTransactionModel(
      id: 'r1',
      amount: 9.99,
      currencyCode: 'EUR',
      categoryId: 'subs',
      type: TransactionType.expense,
      frequency: RecurrenceFrequency.monthly,
      startDate: DateTime(2026, 1, 1),
      nextDueDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 12, 1),
      note: 'Streaming',
      updatedAt: DateTime(2026, 2, 1),
    );

    test('round-trips through toMap/fromMap including the end date', () {
      final DataMap map = withEnd.toMap();
      final RecurringTransactionModel back =
          RecurringTransactionModel.fromMap(map);

      expect(back.id, 'r1');
      expect(back.amount, 9.99);
      expect(back.currencyCode, 'EUR');
      expect(back.categoryId, 'subs');
      expect(back.type, TransactionType.expense);
      expect(back.frequency, RecurrenceFrequency.monthly);
      expect(back.startDate, DateTime(2026, 1, 1));
      expect(back.nextDueDate, DateTime(2026, 3, 1));
      expect(back.endDate, DateTime(2026, 12, 1));
      expect(back.note, 'Streaming');
    });

    test('preserves a null end date and null note', () {
      final RecurringTransactionModel open = RecurringTransactionModel(
        id: 'r2',
        amount: 1200,
        currencyCode: 'USD',
        categoryId: 'salary',
        type: TransactionType.income,
        frequency: RecurrenceFrequency.monthly,
        startDate: DateTime(2026, 1, 25),
        nextDueDate: DateTime(2026, 1, 25),
        updatedAt: DateTime(2026, 1, 1),
      );

      final RecurringTransactionModel back =
          RecurringTransactionModel.fromMap(open.toMap());

      expect(back.endDate, isNull);
      expect(back.note, isNull);
      expect(back.type, TransactionType.income);
    });
  });
}
