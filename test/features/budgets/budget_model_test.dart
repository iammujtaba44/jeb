import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/constants/db_constants.dart';
import 'package:jeb/features/budgets/data/models/budget_model.dart';

void main() {
  group('BudgetModel', () {
    test('overall budget is stored under the overall key', () {
      final model = BudgetModel(
        categoryId: null,
        limitAmount: 500,
        updatedAt: DateTime(2026, 6, 1),
      );
      expect(model.toMap()[DbConstants.columnId], DbConstants.overallBudgetKey);
      expect(model.isOverall, isTrue);
    });

    test('category budget round-trips through the map', () {
      final model = BudgetModel(
        categoryId: 'food',
        limitAmount: 120.5,
        updatedAt: DateTime(2026, 6, 1),
      );
      final restored = BudgetModel.fromMap(model.toMap());
      expect(restored.categoryId, 'food');
      expect(restored.limitAmount, 120.5);
      expect(restored.isOverall, isFalse);
    });

    test('overall key maps back to a null categoryId', () {
      final restored = BudgetModel.fromMap(<String, dynamic>{
        DbConstants.columnId: DbConstants.overallBudgetKey,
        DbConstants.columnLimitAmount: 1000,
        DbConstants.columnUpdatedAt: 0,
        DbConstants.columnIsDeleted: 0,
      });
      expect(restored.categoryId, isNull);
      expect(restored.isOverall, isTrue);
    });
  });
}
