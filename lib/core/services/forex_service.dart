import 'dart:convert';
import 'dart:io';

import 'package:jeb/core/utils/currency_converter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches live exchange rates and feeds them to [CurrencyConverter] so every
/// conversion in the app uses up-to-date FX. Rates are cached on device, so the
/// app works offline (and falls back to the bundled table for anything missing).
///
/// Source: open.er-api.com — free, no API key, sends no personal data (a plain
/// GET for EUR-based rates).
class ForexService {
  ForexService(this._prefs);

  final SharedPreferences _prefs;

  static const String _endpoint = 'https://open.er-api.com/v6/latest/EUR';
  static const String _ratesKey = 'forex_rates_json';
  static const String _updatedKey = 'forex_updated_at';
  static const Duration _maxAge = Duration(hours: 12);

  DateTime? get lastUpdated {
    final int? ms = _prefs.getInt(_updatedKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool get isStale {
    final DateTime? at = lastUpdated;
    return at == null || DateTime.now().difference(at) > _maxAge;
  }

  /// Loads any cached rates into the converter (call once at startup, sync).
  void primeFromCache() {
    final Map<String, double>? cached = _readCache();
    if (cached != null && cached.isNotEmpty) {
      CurrencyConverter.updateRates(cached);
    }
  }

  /// Refreshes from the network only when the cache is missing or stale.
  Future<void> refreshIfStale() async {
    if (isStale) await refresh();
  }

  /// Fetches the latest rates, applies them, and caches. Returns true on
  /// success; never throws (offline simply keeps the existing rates).
  Future<bool> refresh() async {
    try {
      final Map<String, double> ratesToEur = await _fetch();
      if (ratesToEur.isEmpty) return false;
      CurrencyConverter.updateRates(ratesToEur);
      await _prefs.setString(_ratesKey, jsonEncode(ratesToEur));
      await _prefs.setInt(
        _updatedKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, double>? _readCache() {
    final String? raw = _prefs.getString(_ratesKey);
    if (raw == null) return null;
    try {
      final Map<String, dynamic> map =
          jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (String k, dynamic v) => MapEntry<String, double>(
          k,
          (v as num).toDouble(),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, double>> _fetch() async {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final HttpClientRequest request =
          await client.getUrl(Uri.parse(_endpoint));
      final HttpClientResponse response = await request.close();
      if (response.statusCode != 200) return const <String, double>{};
      final String body = await response.transform(utf8.decoder).join();
      return parseRates(jsonDecode(body) as Map<String, dynamic>);
    } finally {
      client.close(force: true);
    }
  }

  /// Pure parser for an open.er-api.com EUR response. The feed gives units per
  /// EUR; the converter wants EUR per unit, so each rate is inverted.
  static Map<String, double> parseRates(Map<String, dynamic> json) {
    if (json['result'] != 'success') return const <String, double>{};
    final Object? rates = json['rates'];
    if (rates is! Map<String, dynamic>) return const <String, double>{};
    final Map<String, double> out = <String, double>{};
    rates.forEach((String code, dynamic value) {
      final double perEur = (value as num).toDouble();
      if (perEur > 0) out[code] = 1.0 / perEur;
    });
    return out;
  }
}
