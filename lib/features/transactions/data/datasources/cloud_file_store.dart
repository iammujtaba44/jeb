import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Transport for the sync snapshot file. Swap the implementation to change
/// *where* the file lives — local disk today, iCloud Drive / Google Drive next.
abstract interface class CloudFileStore {
  Future<String?> readSnapshot();
  Future<void> writeSnapshot(String content);

  /// Relative paths of auxiliary files (e.g. receipt photos) present remotely.
  Future<List<String>> listFiles();

  /// Uploads the file at [localPath] to [relativePath] in the store.
  Future<void> uploadFile(String localPath, String relativePath);

  /// Downloads [relativePath] to [localDestPath]; returns whether it succeeded.
  Future<bool> downloadFile(String relativePath, String localDestPath);
}

/// Writes the snapshot to a local file in the app's documents directory.
///
/// This already works as a backup, and becomes real cross-device sync the
/// moment this directory is an iCloud/Drive-backed container — or when this
/// class is replaced by a dedicated iCloud/Drive [CloudFileStore].
final class LocalFileCloudStore implements CloudFileStore {
  const LocalFileCloudStore();

  static const String _fileName = 'jeb_sync.json';
  static const String _filesDir = 'jeb_cloud';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File(p.join(directory.path, _fileName));
  }

  Future<Directory> _cloudDir() async {
    final directory = await getApplicationDocumentsDirectory();
    final Directory dir = Directory(p.join(directory.path, _filesDir));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
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

  @override
  Future<List<String>> listFiles() async {
    final Directory dir = await _cloudDir();
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .map((File f) => p.relative(f.path, from: dir.path))
        .toList();
  }

  @override
  Future<void> uploadFile(String localPath, String relativePath) async {
    final Directory dir = await _cloudDir();
    final File dest = File(p.join(dir.path, relativePath));
    await dest.parent.create(recursive: true);
    await File(localPath).copy(dest.path);
  }

  @override
  Future<bool> downloadFile(String relativePath, String localDestPath) async {
    final Directory dir = await _cloudDir();
    final File source = File(p.join(dir.path, relativePath));
    if (!await source.exists()) return false;
    await File(localDestPath).parent.create(recursive: true);
    await source.copy(localDestPath);
    return true;
  }
}
