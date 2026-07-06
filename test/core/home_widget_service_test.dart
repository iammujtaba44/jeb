import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/services/home_widget_service.dart';

void main() {
  group('HomeWidgetService.dailyAllowanceText', () {
    test('spreads the remaining budget over the days left (incl. today)', () {
      // July has 31 days; on the 6th there are 26 days left.
      final String text = HomeWidgetService.dailyAllowanceText(
        spent: 54000,
        limit: 80000,
        now: DateTime(2026, 7, 6),
        currency: 'PKR',
      );
      expect(text, 'Rs1,000/day · 26 days left');
    });

    test('says "last day" on the final day of the month', () {
      final String text = HomeWidgetService.dailyAllowanceText(
        spent: 500,
        limit: 800,
        now: DateTime(2026, 7, 31),
        currency: 'USD',
      );
      expect(text, '\$300/day · last day');
    });

    test('empty without a budget or once the budget is spent', () {
      expect(
        HomeWidgetService.dailyAllowanceText(
          spent: 100,
          limit: null,
          now: DateTime(2026, 7, 6),
          currency: 'PKR',
        ),
        isEmpty,
      );
      expect(
        HomeWidgetService.dailyAllowanceText(
          spent: 100,
          limit: 0,
          now: DateTime(2026, 7, 6),
          currency: 'PKR',
        ),
        isEmpty,
      );
      expect(
        HomeWidgetService.dailyAllowanceText(
          spent: 900,
          limit: 800,
          now: DateTime(2026, 7, 6),
          currency: 'PKR',
        ),
        isEmpty,
      );
    });
  });
}
