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
