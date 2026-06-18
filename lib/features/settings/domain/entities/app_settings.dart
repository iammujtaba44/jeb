import 'package:equatable/equatable.dart';
import 'package:jeb/core/constants/app_constants.dart';
import 'package:jeb/features/settings/domain/entities/app_theme_mode.dart';

/// User preferences for the whole app.
class AppSettings extends Equatable {
  const AppSettings({
    required this.defaultCurrencyCode,
    required this.themeMode,
    required this.syncEnabled,
    this.appLockEnabled = false,
    this.lastSyncedAt,
  });

  final String defaultCurrencyCode;
  final AppThemeMode themeMode;
  final bool syncEnabled;
  final bool appLockEnabled;
  final DateTime? lastSyncedAt;

  static const AppSettings defaults = AppSettings(
    defaultCurrencyCode: AppConstants.defaultCurrencyCode,
    themeMode: AppThemeMode.system,
    syncEnabled: true,
  );

  AppSettings copyWith({
    String? defaultCurrencyCode,
    AppThemeMode? themeMode,
    bool? syncEnabled,
    bool? appLockEnabled,
    DateTime? lastSyncedAt,
  }) {
    return AppSettings(
      defaultCurrencyCode: defaultCurrencyCode ?? this.defaultCurrencyCode,
      themeMode: themeMode ?? this.themeMode,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
        defaultCurrencyCode,
        themeMode,
        syncEnabled,
        appLockEnabled,
        lastSyncedAt,
      ];
}
