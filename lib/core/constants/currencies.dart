/// A supported currency. [rateToEur] is how many EUR one unit is worth —
/// approximate, offline values used to total mixed-currency months. Swap for a
/// live FX source later without touching callers.
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
    required this.rateToEur,
  });

  final String code;
  final String symbol;
  final String name;
  final double rateToEur;
}

abstract final class Currencies {
  const Currencies._();

  static const List<Currency> all = <Currency>[
    Currency(code: 'EUR', symbol: '€', name: 'Euro', rateToEur: 1.0),
    Currency(code: 'USD', symbol: r'$', name: 'US Dollar', rateToEur: 0.92),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound', rateToEur: 1.17),
    Currency(code: 'PKR', symbol: '₨', name: 'Pakistani Rupee', rateToEur: 0.0033),
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee', rateToEur: 0.011),
    Currency(code: 'AED', symbol: 'د.إ', name: 'UAE Dirham', rateToEur: 0.25),
    Currency(code: 'SAR', symbol: '﷼', name: 'Saudi Riyal', rateToEur: 0.245),
    Currency(code: 'CAD', symbol: r'C$', name: 'Canadian Dollar', rateToEur: 0.68),
    Currency(code: 'AUD', symbol: r'A$', name: 'Australian Dollar', rateToEur: 0.61),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen', rateToEur: 0.0061),
    Currency(code: 'CHF', symbol: 'CHF', name: 'Swiss Franc', rateToEur: 1.04),
    Currency(code: 'TRY', symbol: '₺', name: 'Turkish Lira', rateToEur: 0.028),
  ];

  static Currency byCode(String code) => all.firstWhere(
        (Currency c) => c.code == code,
        orElse: () => all.first,
      );
}
