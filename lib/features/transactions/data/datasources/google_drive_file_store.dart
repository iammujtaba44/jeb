import 'dart:convert';
import 'dart:io';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:jeb/core/services/google_drive_auth.dart';
import 'package:jeb/features/transactions/data/datasources/cloud_file_store.dart';

/// Stores the sync snapshot (and receipt files) in the user's Google Drive
/// hidden **appDataFolder** — the Android counterpart to [ICloudFileStore].
///
/// When the user hasn't connected Drive yet, every call transparently delegates
/// to [_fallback] (a local file), so the app keeps working and seamlessly
/// "upgrades" to cloud the moment they connect.
final class GoogleDriveCloudStore implements CloudFileStore {
  const GoogleDriveCloudStore({
    required GoogleDriveAuth auth,
    required CloudFileStore fallback,
  })  : _auth = auth,
        _fallback = fallback;

  final GoogleDriveAuth _auth;
  final CloudFileStore _fallback;

  static const String _snapshotName = 'jeb_sync.json';
  static const String _space = 'appDataFolder';

  @override
  Future<String?> readSnapshot() async {
    final drive.DriveApi? api = await _auth.driveApi();
    if (api == null) return _fallback.readSnapshot();
    final String? id = await _findId(api, _snapshotName);
    if (id == null) return null;
    return utf8.decode(await _download(api, id));
  }

  @override
  Future<void> writeSnapshot(String content) async {
    final drive.DriveApi? api = await _auth.driveApi();
    if (api == null) return _fallback.writeSnapshot(content);
    await _put(api, _snapshotName, utf8.encode(content));
  }

  @override
  Future<List<String>> listFiles() async {
    final drive.DriveApi? api = await _auth.driveApi();
    if (api == null) return _fallback.listFiles();
    final drive.FileList result = await api.files.list(
      spaces: _space,
      $fields: 'files(id,name)',
      pageSize: 1000,
    );
    return <String>[
      for (final drive.File f in result.files ?? <drive.File>[])
        if (f.name != null && f.name != _snapshotName) f.name!,
    ];
  }

  @override
  Future<void> uploadFile(String localPath, String relativePath) async {
    final drive.DriveApi? api = await _auth.driveApi();
    if (api == null) return _fallback.uploadFile(localPath, relativePath);
    await _put(api, relativePath, await File(localPath).readAsBytes());
  }

  @override
  Future<bool> downloadFile(String relativePath, String localDestPath) async {
    final drive.DriveApi? api = await _auth.driveApi();
    if (api == null) return _fallback.downloadFile(relativePath, localDestPath);
    final String? id = await _findId(api, relativePath);
    if (id == null) return false;
    final File dest = File(localDestPath);
    await dest.parent.create(recursive: true);
    await dest.writeAsBytes(await _download(api, id));
    return true;
  }

  /// The id of the appData file named [name], or null if it doesn't exist.
  Future<String?> _findId(drive.DriveApi api, String name) async {
    final drive.FileList result = await api.files.list(
      spaces: _space,
      q: "name = '${name.replaceAll(r"\", r"\\").replaceAll("'", r"\'")}'",
      $fields: 'files(id,name)',
      pageSize: 10,
    );
    final List<drive.File>? files = result.files;
    if (files == null || files.isEmpty) return null;
    return files.first.id;
  }

  /// Creates or replaces the appData file [name] with [bytes].
  Future<void> _put(drive.DriveApi api, String name, List<int> bytes) async {
    final drive.Media media =
        drive.Media(Stream<List<int>>.value(bytes), bytes.length);
    final String? existingId = await _findId(api, name);
    if (existingId == null) {
      await api.files.create(
        drive.File(name: name, parents: <String>[_space]),
        uploadMedia: media,
      );
    } else {
      await api.files.update(drive.File(), existingId, uploadMedia: media);
    }
  }

  Future<List<int>> _download(drive.DriveApi api, String id) async {
    final drive.Media media = await api.files.get(
      id,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final List<int> bytes = <int>[];
    await for (final List<int> chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return bytes;
  }
}
