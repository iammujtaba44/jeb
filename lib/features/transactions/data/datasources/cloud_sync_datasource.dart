import 'package:jeb/core/error/exceptions.dart';
import 'package:jeb/features/transactions/data/sync/sync_engine.dart';

/// Abstraction over the user's personal cloud (iCloud on Apple, Google Drive
/// on Android). The app is sync-ready from day one through this seam.
abstract interface class CloudSyncDataSource {
  Future<void> sync();
}

/// Runs the [SyncEngine] and maps low-level errors to [SyncException].
final class CloudSyncDataSourceImpl implements CloudSyncDataSource {
  const CloudSyncDataSourceImpl(this._syncEngine);

  final SyncEngine _syncEngine;

  @override
  Future<void> sync() async {
    try {
      await _syncEngine.sync();
    } catch (error) {
      throw SyncException('Sync failed: $error');
    }
  }
}

/// Disables sync entirely (useful for tests or an opt-out setting).
final class NoOpCloudSyncDataSource implements CloudSyncDataSource {
  const NoOpCloudSyncDataSource();

  @override
  Future<void> sync() async {}
}
