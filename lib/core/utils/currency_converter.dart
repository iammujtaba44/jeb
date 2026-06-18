import 'package:jeb/core/constants/currencies.dart';

/// Converts amounts between currencies via their EUR rate. Used to total a
/// month that mixes currencies into a single home-currency figure.
abstract final class CurrencyConverter {
  const CurrencyConverter._();

  static double convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (from == to) return amount;
    final double inEur = amount * Currencies.byCode(from).rateToEur;
    return inEur / Currencies.byCode(to).rateToEur;
  }
}
