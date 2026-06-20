import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeb/core/services/notification_service.dart';
import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/entities/app_theme_mode.dart';
import 'package:jeb/features/settings/domain/usecases/get_settings.dart';
import 'package:jeb/features/settings/domain/usecases/save_settings.dart';
import 'package:jeb/features/transactions/domain/usecases/sync_data.dart';

part 'settings_state.dart';

/// App-wide settings + backup control. Provided above [MaterialApp] so the
/// theme reacts and any screen can read the default currency.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required GetSettings getSettings,
    required SaveSettings saveSettings,
    required SyncData syncData,
    required NotificationService notifications,
  })  : _getSettings = getSettings,
        _saveSettings = saveSettings,
        _syncData = syncData,
        _notifications = notifications,
        super(const SettingsState(settings: AppSettings.defaults));

  final GetSettings _getSettings;
  final SaveSettings _saveSettings;
  final SyncData _syncData;
  final NotificationService _notifications;

  Future<void> load() async {
    final result = await _getSettings(const NoParams());
    await result.fold(
      (_) async => emit(state.copyWith(isLoaded: true)),
      (AppSettings settings) async {
        emit(state.copyWith(settings: settings, isLoaded: true));
        // Re-arm the reminder on launch (survives reboots / OS clearing it).
        if (settings.reminderEnabled) {
          await _notifications.scheduleDailyReminder(
            settings.reminderHour,
            settings.reminderMinute,
          );
        }
      },
    );
  }

  /// Finishes first-run setup: stores the chosen currency + backup preference
  /// and marks onboarding complete.
  Future<void> completeOnboarding({
    required String currencyCode,
    required bool syncEnabled,
  }) {
    return _persist(state.settings.copyWith(
      defaultCurrencyCode: currencyCode,
      syncEnabled: syncEnabled,
      onboardingComplete: true,
    ));
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _persist(state.settings.copyWith(themeMode: mode));

  Future<void> setDefaultCurrency(String currencyCode) =>
      _persist(state.settings.copyWith(defaultCurrencyCode: currencyCode));

  Future<void> setSyncEnabled(bool enabled) =>
      _persist(state.settings.copyWith(syncEnabled: enabled));

  Future<void> setAppLock(bool enabled) =>
      _persist(state.settings.copyWith(appLockEnabled: enabled));

  /// Turns the daily reminder on/off, requesting OS permission when enabling.
  Future<void> setReminderEnabled(bool enabled) async {
    await _persist(state.settings.copyWith(reminderEnabled: enabled));
    if (enabled) {
      await _notifications.requestPermission();
      await _notifications.scheduleDailyReminder(
        state.settings.reminderHour,
        state.settings.reminderMinute,
      );
    } else {
      await _notifications.cancelReminder();
    }
  }

  /// Updates the reminder time (minutes since midnight) and reschedules.
  Future<void> setReminderMinutes(int minutes) async {
    await _persist(state.settings.copyWith(reminderMinutes: minutes));
    if (state.settings.reminderEnabled) {
      await _notifications.scheduleDailyReminder(
        state.settings.reminderHour,
        state.settings.reminderMinute,
      );
    }
  }

  Future<void> _persist(AppSettings settings) async {
    // Stamp the change time so last-write-wins sync can order preferences.
    final AppSettings stamped = settings.copyWith(updatedAt: DateTime.now());
    emit(state.copyWith(settings: stamped));
    await _saveSettings(stamped);
  }

  Future<void> backupNow() async {
    if (!state.settings.syncEnabled || state.syncStatus == SyncStatus.syncing) {
      return;
    }
    emit(state.copyWith(syncStatus: SyncStatus.syncing));

    final result = await _syncData(const NoParams());
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          syncStatus: SyncStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) async {
        final AppSettings updated =
            state.settings.copyWith(lastSyncedAt: DateTime.now());
        await _saveSettings(updated);
        emit(state.copyWith(settings: updated, syncStatus: SyncStatus.success));
      },
    );
  }
}
