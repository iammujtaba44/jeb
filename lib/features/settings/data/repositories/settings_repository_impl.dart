import 'package:dartz/dartz.dart';
import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/core/error/failures.dart';
import 'package:jeb/core/utils/typedefs.dart';
import 'package:jeb/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:jeb/features/settings/domain/entities/app_settings.dart';
import 'package:jeb/features/settings/domain/repositories/settings_repository.dart';

final class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._localDataSource);

  final SettingsLocalDataSource _localDataSource;

  @override
  ResultFuture<AppSettings> getSettings() async {
    try {
      return Right(await _localDataSource.read());
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }

  @override
  ResultVoid saveSettings(AppSettings settings) async {
    try {
      await _localDataSource.write(settings);
      return const Right(null);
    } on CacheException catch (error) {
      return Left(CacheFailure(error.message));
    } catch (error) {
      return Left(UnknownFailure(error.toString()));
    }
  }
}
