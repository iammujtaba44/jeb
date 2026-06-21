import 'package:flutter_test/flutter_test.dart';
import 'package:jeb/core/services/forex_service.dart';
import 'package:jeb/core/utils/currency_converter.dart';

void main() {
  group('ForexService.parseRates', () {
    test('inverts units-per-EUR into EUR-per-unit', () {
      final Map<String, double> out = ForexService.parseRates(
        <String, dynamic>{
          'result': 'success',
          'base_code': 'EUR',
          'rates': <String, dynamic>{'EUR': 1.0, 'USD': 1.08, 'PKR': 300.0},
        },
      );
      expect(out['EUR'], closeTo(1.0, 1e-9));
      expect(out['USD'], closeTo(1 / 1.08, 1e-9));
      expect(out['PKR'], closeTo(1 / 300.0, 1e-9));
    });

    test('returns empty when the feed is not a success', () {
      expect(
        ForexService.parseRates(<String, dynamic>{'result': 'error'}),
        isEmpty,
      );
      expect(
        ForexService.parseRates(<String, dynamic>{'result': 'success'}),
        isEmpty,
      );
    });

    test('skips non-positive rates', () {
      final Map<String, double> out = ForexService.parseRates(
        <String, dynamic>{
          'result': 'success',
          'rates': <String, dynamic>{'A': 0, 'B': -2, 'C': 2.0},
        },
      );
      expect(out.containsKey('A'), isFalse);
      expect(out.containsKey('B'), isFalse);
      expect(out['C'], closeTo(0.5, 1e-9));
    });
  });

  group('CurrencyConverter live rates', () {
    tearDown(() => CurrencyConverter.updateRates(const <String, double>{}));

    test('uses live rates once loaded', () {
      CurrencyConverter.updateRates(<String, double>{'USD': 0.90, 'EUR': 1.0});
      expect(CurrencyConverter.hasLiveRates, isTrue);
      // 100 USD -> EUR = 100 * 0.90 / 1.0
      expect(
        CurrencyConverter.convert(amount: 100, from: 'USD', to: 'EUR'),
        closeTo(90, 1e-9),
      );
    });

    test('falls back to the bundled rate for currencies the feed omits', () {
      CurrencyConverter.updateRates(<String, double>{'USD': 0.90});
      // PKR not in the feed -> bundled 0.0033 EUR/unit.
      expect(
        CurrencyConverter.convert(amount: 1000, from: 'PKR', to: 'EUR'),
        closeTo(1000 * 0.0033, 1e-9),
      );
    });

    test('same currency returns the amount unchanged', () {
      CurrencyConverter.updateRates(<String, double>{'USD': 0.90});
      expect(
        CurrencyConverter.convert(amount: 50, from: 'USD', to: 'USD'),
        50,
      );
    });
  });
}
