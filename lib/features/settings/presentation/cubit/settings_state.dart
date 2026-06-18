part of 'settings_cubit.dart';

enum SyncStatus { idle, syncing, success, failure }

final class SettingsState extends Equatable {
  const SettingsState({
    required this.settings,
    this.syncStatus = SyncStatus.idle,
    this.errorMessage,
  });

  final AppSettings settings;
  final SyncStatus syncStatus;
  final String? errorMessage;

  SettingsState copyWith({
    AppSettings? settings,
    SyncStatus? syncStatus,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [settings, syncStatus, errorMessage];
}
