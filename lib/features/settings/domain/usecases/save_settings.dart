import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/repositories/settings_repository.dart';

final class SaveSettings extends UseCase<void, AppSettings> {
  const SaveSettings(this._repository);

  final SettingsRepository _repository;

  @override
  ResultVoid call(AppSettings params) => _repository.saveSettings(params);
}
