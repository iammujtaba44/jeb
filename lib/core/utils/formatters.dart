import 'package:intl/intl.dart';

/// Formats monetary amounts with the correct currency symbol.
abstract final class MoneyFormatter {
  const MoneyFormatter._();

  static String format(double amount, String currencyCode) {
    final NumberFormat formatter = NumberFormat.simpleCurrency(
      name: currencyCode,
    );
    return formatter.format(amount);
  }

  /// Headline figures: the full amount with comma grouping, up to two
  /// decimals with trailing zeros stripped (e.g. Rs2,800,000 · $1,250.5).
  /// No Lakh/Crore or K/M/B collapsing — balances always read in full.
  static String compact(double amount, String currencyCode) {
    final String symbol =
        NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
    final String sign = amount < 0 ? '-' : '';
    return '$sign$symbol${NumberFormat('#,##0.##').format(amount.abs())}';
  }
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
