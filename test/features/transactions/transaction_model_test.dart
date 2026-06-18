import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/transactions/data/models/transaction_model.dart';
import 'package:jeb/features/transactions/domain/entities/transaction.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';

void main() {
  group('TransactionModel', () {
    test('round-trips recurringId and receiptPath through the map', () {
      final TransactionModel model = TransactionModel(
        id: 't1',
        amount: 12.5,
        currencyCode: 'EUR',
        categoryId: 'food',
        date: DateTime(2026, 6, 14),
        type: TransactionType.expense,
        note: 'Lunch',
        recurringId: 'rule-9',
        receiptPath: 'receipts/abc.jpg',
        updatedAt: DateTime(2026, 6, 14, 10),
      );

      final DataMap map = model.toMap();
      final TransactionModel back = TransactionModel.fromMap(map);

      expect(back.recurringId, 'rule-9');
      expect(back.receiptPath, 'receipts/abc.jpg');
      expect(back.isRecurring, isTrue);
      expect(back.hasReceipt, isTrue);
    });

    test('fromEntity carries the new fields and defaults them to null', () {
      final Transaction plain = Transaction(
        id: 't2',
        amount: 4,
        currencyCode: 'USD',
        categoryId: 'coffee',
        date: DateTime(2026, 1, 1),
        type: TransactionType.expense,
      );
      final TransactionModel model =
          TransactionModel.fromEntity(plain, updatedAt: DateTime(2026, 1, 1));
      expect(model.recurringId, isNull);
      expect(model.receiptPath, isNull);
      expect(model.isRecurring, isFalse);
      expect(model.hasReceipt, isFalse);
    });
  });
}
