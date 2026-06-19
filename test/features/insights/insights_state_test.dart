import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/insights/presentation/cubit/insights_cubit.dart';

void main() {
  group('InsightsState', () {
    InsightsState withMonths(List<double> expenses) => InsightsState(
          isLoading: false,
          currency: 'EUR',
          months: <MonthStat>[
            for (int i = 0; i < expenses.length; i++)
              MonthStat(
                month: DateTime(2026, i + 1),
                expense: expenses[i],
                income: 0,
              ),
          ],
        );

    test('currentExpense and previousExpense read the last two months', () {
      final InsightsState s = withMonths(<double>[100, 150, 200]);
      expect(s.currentExpense, 200);
      expect(s.previousExpense, 150);
    });

    test('momChange is the fractional change vs last month', () {
      expect(withMonths(<double>[100, 200]).momChange, 1.0); // +100%
      expect(withMonths(<double>[200, 150]).momChange, closeTo(-0.25, 1e-9));
    });

    test('momChange is null when the previous month had no spend', () {
      expect(withMonths(<double>[0, 120]).momChange, isNull);
      expect(const InsightsState().momChange, isNull);
    });

    test('maxMonthlyExpense returns the largest month', () {
      expect(withMonths(<double>[100, 320, 50]).maxMonthlyExpense, 320);
    });
  });
}
