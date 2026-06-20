import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/utils/formatters.dart';

void main() {
  group('MoneyFormatter.compact', () {
    test('uses Lakh/Crore for Rs-style currencies', () {
      expect(MoneyFormatter.compact(25000000, 'PKR'), contains('2.5 Cr'));
      expect(MoneyFormatter.compact(2800000, 'PKR'), contains('28 Lac'));
      expect(MoneyFormatter.compact(150000, 'INR'), contains('1.5 Lac'));
    });

    test('uses K/M/B for other currencies', () {
      expect(MoneyFormatter.compact(2500000, 'USD'), contains('2.5M'));
      expect(MoneyFormatter.compact(1500000000, 'USD'), contains('1.5B'));
    });

    test('shows full grouped digits for small amounts (no .00)', () {
      final String s = MoneyFormatter.compact(50000, 'PKR');
      expect(s, contains('50,000'));
      expect(s, isNot(contains('.00')));
    });

    test('keeps the negative sign', () {
      expect(MoneyFormatter.compact(-25000000, 'PKR'), startsWith('-'));
    });
  });
}
