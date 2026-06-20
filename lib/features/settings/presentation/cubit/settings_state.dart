part of 'settings_cubit.dart';

enum SyncStatus { idle, syncing, success, failure }

final class SettingsState extends Equatable {
  const SettingsState({
    required this.settings,
    this.isLoaded = false,
    this.syncStatus = SyncStatus.idle,
    this.errorMessage,
  });

  final AppSettings settings;

  /// Whether settings have been read from storage at least once (so the app
  /// doesn't flash onboarding before the stored flag is known).
  final bool isLoaded;
  final SyncStatus syncStatus;
  final String? errorMessage;

  SettingsState copyWith({
    AppSettings? settings,
    bool? isLoaded,
    SyncStatus? syncStatus,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoaded: isLoaded ?? this.isLoaded,
      syncStatus: syncStatus ?? this.syncStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [settings, isLoaded, syncStatus, errorMessage];
}
