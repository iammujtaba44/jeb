import 'dart:async';
import 'dart:io';

import 'package:icloud_storage/icloud_storage.dart';
import 'package:jeb/core/constants/app_constants.dart';
import 'package:jeb/features/transactions/data/datasources/cloud_file_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores the sync snapshot in the user's private iCloud Drive container.
///
/// iCloud uploads/downloads complete asynchronously, so each transfer is
/// awaited via its progress stream (with a safety timeout).
final class ICloudFileStore implements CloudFileStore {
  const ICloudFileStore();

  static const String _fileName = 'jeb_sync.json';
  static const Duration _transferTimeout = Duration(seconds: 30);

  String get _containerId => AppConstants.iCloudContainerId;

  Future<String> _localCachePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, _fileName);
  }

  @override
  Future<String?> readSnapshot() async {
    final List<ICloudFile> files =
        await ICloudStorage.gather(containerId: _containerId);
    final bool exists =
        files.any((ICloudFile f) => f.relativePath == _fileName);
    if (!exists) return null;

    final String destination = await _localCachePath();
    await _awaitTransfer(
      (void Function(Stream<double>) onProgress) => ICloudStorage.download(
        containerId: _containerId,
        relativePath: _fileName,
        destinationFilePath: destination,
        onProgress: onProgress,
      ),
    );

    final File file = File(destination);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> writeSnapshot(String content) async {
    final String path = await _localCachePath();
    await File(path).writeAsString(content, flush: true);

    await _awaitTransfer(
      (void Function(Stream<double>) onProgress) => ICloudStorage.upload(
        containerId: _containerId,
        filePath: path,
        destinationRelativePath: _fileName,
        onProgress: onProgress,
      ),
    );
  }

  /// iCloud transfer APIs return before the transfer finishes; this resolves
  /// once the progress stream closes (or after [_transferTimeout]).
  Future<void> _awaitTransfer(
    Future<void> Function(void Function(Stream<double>) onProgress) action,
  ) async {
    final Completer<void> completer = Completer<void>();
    await action((Stream<double> stream) {
      stream.listen(
        (_) {},
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
        cancelOnError: true,
      );
    });
    await completer.future.timeout(_transferTimeout, onTimeout: () {});
  }
}
