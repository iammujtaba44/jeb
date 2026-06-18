import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/features/recurring/domain/entities/recurrence_frequency.dart';

void main() {
  group('RecurrenceFrequency.nextAfter', () {
    test('daily advances by one day, rolling over month end', () {
      expect(
        RecurrenceFrequency.daily.nextAfter(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 1),
      );
    });

    test('weekly advances by seven days, rolling over month end', () {
      expect(
        RecurrenceFrequency.weekly.nextAfter(DateTime(2026, 1, 28)),
        DateTime(2026, 2, 4),
      );
    });

    test('monthly keeps the day when the next month is long enough', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(DateTime(2026, 1, 15)),
        DateTime(2026, 2, 15),
      );
    });

    test('monthly clamps the 31st to the last day of a shorter month', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28), // 2026 is not a leap year
      );
    });

    test('monthly clamps to Feb 29 in a leap year', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(DateTime(2024, 1, 31)),
        DateTime(2024, 2, 29),
      );
    });

    test('monthly rolls over the year boundary', () {
      expect(
        RecurrenceFrequency.monthly.nextAfter(DateTime(2026, 12, 15)),
        DateTime(2027, 1, 15),
      );
    });

    test('yearly advances by a year, clamping Feb 29 to Feb 28', () {
      expect(
        RecurrenceFrequency.yearly.nextAfter(DateTime(2024, 2, 29)),
        DateTime(2025, 2, 28),
      );
    });

    test('storage value round-trips', () {
      for (final RecurrenceFrequency f in RecurrenceFrequency.values) {
        expect(RecurrenceFrequency.fromStorage(f.storageValue), f);
      }
    });

    test('fromStorage falls back to monthly for unknown values', () {
      expect(RecurrenceFrequency.fromStorage('nonsense'),
          RecurrenceFrequency.monthly);
    });
  });
}
