import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/entities/app_theme_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SettingsLocalDataSource {
  Future<AppSettings> read();
  Future<void> write(AppSettings settings);
}

final class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  const SettingsLocalDataSourceImpl(this._prefs);

  final SharedPreferences _prefs;

  static const String _keyCurrency = 'settings.default_currency';
  static const String _keyTheme = 'settings.theme_mode';
  static const String _keySync = 'settings.sync_enabled';
  static const String _keyAppLock = 'settings.app_lock_enabled';
  static const String _keyLastSynced = 'settings.last_synced_at';

  @override
  Future<AppSettings> read() async {
    try {
      final int? lastMs = _prefs.getInt(_keyLastSynced);
      return AppSettings(
        defaultCurrencyCode: _prefs.getString(_keyCurrency) ??
            AppSettings.defaults.defaultCurrencyCode,
        themeMode: AppThemeMode.fromStorage(_prefs.getString(_keyTheme)),
        syncEnabled: _prefs.getBool(_keySync) ?? AppSettings.defaults.syncEnabled,
        appLockEnabled: _prefs.getBool(_keyAppLock) ??
            AppSettings.defaults.appLockEnabled,
        lastSyncedAt:
            lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
      );
    } catch (error) {
      throw CacheException('Failed to read settings: $error');
    }
  }

  @override
  Future<void> write(AppSettings settings) async {
    try {
      await _prefs.setString(_keyCurrency, settings.defaultCurrencyCode);
      await _prefs.setString(_keyTheme, settings.themeMode.storageValue);
      await _prefs.setBool(_keySync, settings.syncEnabled);
      await _prefs.setBool(_keyAppLock, settings.appLockEnabled);
      final DateTime? lastSynced = settings.lastSyncedAt;
      if (lastSynced != null) {
        await _prefs.setInt(_keyLastSynced, lastSynced.millisecondsSinceEpoch);
      }
    } catch (error) {
      throw CacheException('Failed to save settings: $error');
    }
  }
}
