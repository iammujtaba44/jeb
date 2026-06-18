import 'package:jeb/core/usecase/usecase.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/repositories/settings_repository.dart';

final class GetSettings extends UseCase<AppSettings, NoParams> {
  const GetSettings(this._repository);

  final SettingsRepository _repository;

  @override
  ResultFuture<AppSettings> call(NoParams params) => _repository.getSettings();
}
