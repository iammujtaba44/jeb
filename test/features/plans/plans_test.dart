import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/plans/data/models/plan_model.dart';
import 'package:jeb/features/plans/data/models/plan_payment_model.dart';
import 'package:jeb/features/plans/domain/entities/plan.dart';
import 'package:jeb/features/plans/domain/entities/plan_kind.dart';
import 'package:jeb/features/plans/presentation/cubit/plans_cubit.dart';

void main() {
  test('PlansState.netWorth is assets minus liabilities', () {
    const PlansState s = PlansState(
      isLoading: false,
      totalAssets: 2800000,
      totalLiabilities: 1000000,
      hasNetWorth: true,
    );
    expect(s.netWorth, 1800000);
  });

  Plan plan({double? target, double? installment}) => Plan(
        id: 'p1',
        name: 'House',
        kind: PlanKind.asset,
        currencyCode: 'PKR',
        startDate: DateTime(2026, 1, 1),
        targetAmount: target,
        installmentAmount: installment,
      );

  group('Plan progress', () {
    test('progress is the clamped fraction paid, or null without a target', () {
      expect(plan(target: 200).progress(50), 0.25);
      expect(plan(target: 200).progress(300), 1.0); // clamped
      expect(plan().progress(50), isNull); // open-ended
    });

    test('remaining and isComplete', () {
      final Plan p = plan(target: 200);
      expect(p.remaining(50), 150);
      expect(p.remaining(250), 0); // never negative
      expect(p.isComplete(199), isFalse);
      expect(p.isComplete(200), isTrue);
    });

    test('monthsLeft uses the per-month installment', () {
      expect(plan(target: 200, installment: 50).monthsLeft(40), 4); // ceil(160/50)
      expect(plan(target: 200, installment: 50).monthsLeft(200), 0);
      expect(plan(target: 200).monthsLeft(40), isNull); // no installment
      expect(plan(installment: 50).monthsLeft(40), isNull); // no target
    });
  });

  group('models round-trip through the map', () {
    test('PlanModel', () {
      final PlanModel model = PlanModel(
        id: 'p1',
        name: 'Car loan',
        kind: PlanKind.loan,
        currencyCode: 'PKR',
        startDate: DateTime(2026, 1, 1),
        targetAmount: 2500000,
        installmentAmount: 200000,
        note: '24 months',
        updatedAt: DateTime(2026, 1, 2),
      );
      final DataMap map = model.toMap();
      final PlanModel back = PlanModel.fromMap(map);
      expect(back.name, 'Car loan');
      expect(back.kind, PlanKind.loan);
      expect(back.targetAmount, 2500000);
      expect(back.installmentAmount, 200000);
      expect(back.note, '24 months');
    });

    test('PlanModel keeps null target/installment open-ended', () {
      final PlanModel back = PlanModel.fromMap(
        PlanModel(
          id: 'p2',
          name: 'Sadqa',
          kind: PlanKind.giving,
          currencyCode: 'PKR',
          startDate: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ).toMap(),
      );
      expect(back.targetAmount, isNull);
      expect(back.installmentAmount, isNull);
      expect(back.hasTarget, isFalse);
    });

    test('PlanPaymentModel', () {
      final PlanPaymentModel back = PlanPaymentModel.fromMap(
        PlanPaymentModel(
          id: 'pay1',
          planId: 'p1',
          amount: 200000,
          date: DateTime(2026, 2, 1),
          note: 'Feb installment',
          updatedAt: DateTime(2026, 2, 1),
        ).toMap(),
      );
      expect(back.planId, 'p1');
      expect(back.amount, 200000);
      expect(back.note, 'Feb installment');
      expect(back.receiptPaths, isEmpty);
    });

    test('PlanPaymentModel round-trips its receipt paths', () {
      final PlanPaymentModel back = PlanPaymentModel.fromMap(
        PlanPaymentModel(
          id: 'pay2',
          planId: 'p1',
          amount: 200000,
          date: DateTime(2026, 2, 1),
          receiptPaths: const <String>['receipts/a.jpg', 'receipts/b.jpg'],
          updatedAt: DateTime(2026, 2, 1),
        ).toMap(),
      );
      expect(back.receiptPaths, <String>['receipts/a.jpg', 'receipts/b.jpg']);
      expect(back.hasReceipts, isTrue);
    });
  });
}
