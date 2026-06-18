import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/transactions/domain/entities/transaction_type.dart';
import 'package:jeb/features/transactions/presentation/cubit/add_transaction_cubit.dart';

void main() {
  AddTransactionState baseState() =>
      AddTransactionState(date: DateTime(2026, 6, 14));

  group('AddTransactionState.canSubmit', () {
    test('is false without an amount', () {
      final state = baseState().copyWith(selectedCategoryId: 'food');
      expect(state.canSubmit, isFalse);
    });

    test('is false without a category', () {
      final state = baseState().copyWith(amount: 12);
      expect(state.canSubmit, isFalse);
    });

    test('is true with amount and category', () {
      final state =
          baseState().copyWith(amount: 12, selectedCategoryId: 'food');
      expect(state.canSubmit, isTrue);
    });
  });

  test('changing type clears the selected category', () {
    final state = baseState()
        .copyWith(selectedCategoryId: 'food')
        .copyWith(type: TransactionType.income, clearCategory: true);
    expect(state.selectedCategoryId, isNull);
    expect(state.type, TransactionType.income);
  });
}
