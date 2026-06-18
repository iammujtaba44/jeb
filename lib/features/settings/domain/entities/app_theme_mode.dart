/// Theme preference, kept Flutter-free in the domain layer.
enum AppThemeMode {
  system,
  light,
  dark;

  String get storageValue => name;

  static AppThemeMode fromStorage(String? value) {
    return AppThemeMode.values.firstWhere(
      (AppThemeMode mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }
}
