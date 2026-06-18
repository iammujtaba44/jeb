import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';

abstract interface class SettingsRepository {
  ResultFuture<AppSettings> getSettings();
  ResultVoid saveSettings(AppSettings settings);
}
