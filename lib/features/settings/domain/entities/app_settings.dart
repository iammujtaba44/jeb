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
    this.reminderEnabled = false,
    this.reminderMinutes = 20 * 60, // 20:00
    this.lastSyncedAt,
  });

  final String defaultCurrencyCode;
  final AppThemeMode themeMode;
  final bool syncEnabled;
  final bool appLockEnabled;

  /// Whether the daily "log your spending" reminder is on.
  final bool reminderEnabled;

  /// Time of the daily reminder, as minutes since midnight (local time).
  final int reminderMinutes;

  final DateTime? lastSyncedAt;

  int get reminderHour => reminderMinutes ~/ 60;
  int get reminderMinute => reminderMinutes % 60;

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
    bool? reminderEnabled,
    int? reminderMinutes,
    DateTime? lastSyncedAt,
  }) {
    return AppSettings(
      defaultCurrencyCode: defaultCurrencyCode ?? this.defaultCurrencyCode,
      themeMode: themeMode ?? this.themeMode,
      syncEnabled: syncEnabled ?? this.syncEnabled,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  @override
  List<Object?> get props => [
        defaultCurrencyCode,
        themeMode,
        syncEnabled,
        appLockEnabled,
        reminderEnabled,
        reminderMinutes,
        lastSyncedAt,
      ];
}
