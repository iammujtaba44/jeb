import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/utils/formatters.dart';

void main() {
  group('MoneyFormatter.compact', () {
    test('shows the full amount with comma grouping (no Lakh/Crore)', () {
      expect(MoneyFormatter.compact(25000000, 'PKR'), contains('25,000,000'));
      expect(MoneyFormatter.compact(2800000, 'PKR'), contains('2,800,000'));
      expect(MoneyFormatter.compact(2500000, 'USD'), contains('2,500,000'));
    });

    test('shows full grouped digits for small amounts (no .00)', () {
      final String s = MoneyFormatter.compact(50000, 'PKR');
      expect(s, contains('50,000'));
      expect(s, isNot(contains('.00')));
    });

    test('keeps up to two decimals when not whole', () {
      expect(MoneyFormatter.compact(1250.5, 'USD'), contains('1,250.5'));
    });

    test('keeps the negative sign', () {
      expect(MoneyFormatter.compact(-25000000, 'PKR'), startsWith('-'));
    });
  });
}
