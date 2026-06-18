import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  })  : _getSettings = getSettings,
        _saveSettings = saveSettings,
        _syncData = syncData,
        super(const SettingsState(settings: AppSettings.defaults));

  final GetSettings _getSettings;
  final SaveSettings _saveSettings;
  final SyncData _syncData;

  Future<void> load() async {
    final result = await _getSettings(const NoParams());
    result.fold(
      (_) {},
      (AppSettings settings) => emit(state.copyWith(settings: settings)),
    );
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _persist(state.settings.copyWith(themeMode: mode));

  Future<void> setDefaultCurrency(String currencyCode) =>
      _persist(state.settings.copyWith(defaultCurrencyCode: currencyCode));

  Future<void> setSyncEnabled(bool enabled) =>
      _persist(state.settings.copyWith(syncEnabled: enabled));

  Future<void> setAppLock(bool enabled) =>
      _persist(state.settings.copyWith(appLockEnabled: enabled));

  Future<void> _persist(AppSettings settings) async {
    emit(state.copyWith(settings: settings));
    await _saveSettings(settings);
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
