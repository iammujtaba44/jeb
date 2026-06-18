import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Transport for the sync snapshot file. Swap the implementation to change
/// *where* the file lives — local disk today, iCloud Drive / Google Drive next.
abstract interface class CloudFileStore {
  Future<String?> readSnapshot();
  Future<void> writeSnapshot(String content);
}

/// Writes the snapshot to a local file in the app's documents directory.
///
/// This already works as a backup, and becomes real cross-device sync the
/// moment this directory is an iCloud/Drive-backed container — or when this
/// class is replaced by a dedicated iCloud/Drive [CloudFileStore].
final class LocalFileCloudStore implements CloudFileStore {
  const LocalFileCloudStore();

  static const String _fileName = 'jeb_sync.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }

  @override
  Future<String?> readSnapshot() async {
    final File file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  @override
  Future<void> writeSnapshot(String content) async {
    final File file = await _file();
    await file.writeAsString(content, flush: true);
  }
}
