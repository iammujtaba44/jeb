import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/insights/presentation/cubit/insights_cubit.dart';

void main() {
  final DateTime m = DateTime(2026, 1);
  MonthStat stat(double expense) =>
      MonthStat(month: m, expense: expense, income: 0);
  MonthBudgetCheck check(double expense, double? budget) => MonthBudgetCheck(
        month: m,
        expense: expense,
        budget: budget,
        drivers: const <CategorySpend>[],
      );

  group('InsightsState', () {
    test('totalSavings is income minus spending', () {
      const InsightsState s = InsightsState(
        isLoading: false,
        totalIncome: 2000,
        totalSpending: 1500,
      );
      expect(s.totalSavings, 500);
    });

    test('totalBudget scales the monthly budget across the range', () {
      const InsightsState s = InsightsState(
        isLoading: false,
        rangeMonths: 6,
        budgetPerMonth: 300,
      );
      expect(s.totalBudget, 1800);
    });

    test('totalBudget is null when no budget is set', () {
      expect(const InsightsState().totalBudget, isNull);
    });

    test('maxMonthlyExpense returns the largest month', () {
      final InsightsState s = InsightsState(
        isLoading: false,
        months: <MonthStat>[stat(100), stat(320), stat(50)],
      );
      expect(s.maxMonthlyExpense, 320);
    });

    test('monthsOverBudget counts exceeded checks', () {
      final InsightsState s = InsightsState(
        isLoading: false,
        checks: <MonthBudgetCheck>[check(350, 300), check(200, 300)],
      );
      expect(s.monthsOverBudget, 1);
    });
  });

  group('MonthBudgetCheck', () {
    test('exceeded / over / remaining reflect the budget', () {
      final MonthBudgetCheck over = check(420, 300);
      expect(over.exceeded, isTrue);
      expect(over.over, 120);

      final MonthBudgetCheck under = check(250, 300);
      expect(under.exceeded, isFalse);
      expect(under.remaining, 50);
    });

    test('no budget means never exceeded', () {
      final MonthBudgetCheck none = check(999, null);
      expect(none.hasBudget, isFalse);
      expect(none.exceeded, isFalse);
    });
  });
}
