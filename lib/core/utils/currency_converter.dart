import 'package:jeb/core/constants/currencies.dart';

/// Converts amounts between currencies via their EUR rate. Used to total a
/// month that mixes currencies into a single home-currency figure.
///
/// Rates default to the bundled offline table in [Currencies], but a live FX
/// source can override them at runtime via [updateRates] — every caller picks
/// up the new rates without changing, and falls back to the bundled value for
/// any currency the live feed doesn't cover.
abstract final class CurrencyConverter {
  const CurrencyConverter._();

  /// Live EUR-per-unit rates, keyed by currency code. Empty until a feed loads.
  static Map<String, double> _liveRatesToEur = const <String, double>{};

  /// Replaces the live rate table (e.g. after a forex fetch).
  static void updateRates(Map<String, double> ratesToEur) =>
      _liveRatesToEur = ratesToEur;

  /// Whether any live rates are currently in use.
  static bool get hasLiveRates => _liveRatesToEur.isNotEmpty;

  /// EUR worth of one unit of [code]: live rate if available, else bundled.
  static double rateToEur(String code) =>
      _liveRatesToEur[code] ?? Currencies.byCode(code).rateToEur;

  static double convert({
    required double amount,
    required String from,
    required String to,
  }) {
    if (from == to) return amount;
    return amount * rateToEur(from) / rateToEur(to);
  }
}
