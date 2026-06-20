import 'package:intl/intl.dart';

/// Formats monetary amounts with the correct currency symbol.
abstract final class MoneyFormatter {
  const MoneyFormatter._();

  /// Currencies that group by the lakh/crore (South-Asian) system.
  static const Set<String> _lakhCrore = <String>{
    'PKR',
    'INR',
    'NPR',
    'LKR',
    'BDT',
  };

  static String format(double amount, String currencyCode) {
    final NumberFormat formatter = NumberFormat.simpleCurrency(
      name: currencyCode,
    );
    return formatter.format(amount);
  }

  /// A short, readable form for headline figures. Large amounts collapse to
  /// Lakh/Crore for Rs-style currencies, or K/M/B otherwise; the trailing
  /// ".00" is dropped. Small amounts fall back to grouped digits.
  static String compact(double amount, String currencyCode) {
    final String symbol =
        NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
    final double abs = amount.abs();
    final String sign = amount < 0 ? '-' : '';

    if (_lakhCrore.contains(currencyCode)) {
      if (abs >= 10000000) return '$sign$symbol${_trim(abs / 10000000)} Cr';
      if (abs >= 100000) return '$sign$symbol${_trim(abs / 100000)} Lac';
    } else {
      if (abs >= 1000000000) return '$sign$symbol${_trim(abs / 1000000000)}B';
      if (abs >= 1000000) return '$sign$symbol${_trim(abs / 1000000)}M';
    }
    // Small enough to show in full (no decimals when whole).
    return '$sign$symbol${NumberFormat('#,##0.##').format(abs)}';
  }

  /// Up to two decimals, trailing zeros stripped (e.g. 2.5, 28, 2.22).
  static String _trim(double value) => NumberFormat('#,##0.##').format(value);
}

/// Formats dates for display throughout the app.
abstract final class DateFormatter {
  const DateFormatter._();

  static String dayMonth(DateTime date) => DateFormat.MMMd().format(date);

  static String monthYear(DateTime date) => DateFormat.yMMMM().format(date);

  static String fullDate(DateTime date) => DateFormat.yMMMMd().format(date);

  static String dateTime(DateTime date) =>
      DateFormat.MMMd().add_jm().format(date);
}
