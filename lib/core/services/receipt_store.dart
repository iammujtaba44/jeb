import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Stores receipt photos inside the app's documents directory. Transactions
/// keep a *relative* path (e.g. `receipts/<uuid>.jpg`) so the reference stays
/// valid even if the sandbox's absolute path changes between launches.
class ReceiptStore {
  ReceiptStore(this._uuid);

  final Uuid _uuid;
  String? _baseDir;

  static const String _folder = 'receipts';

  /// Resolves and creates the receipts folder. Call once at startup.
  Future<void> init() async {
    if (_baseDir != null) return;
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory receipts = Directory(p.join(dir.path, _folder));
    if (!receipts.existsSync()) receipts.createSync(recursive: true);
    _baseDir = dir.path;
  }

  /// Absolute path for a stored [relative] receipt path.
  String absolutePath(String relative) => p.join(_baseDir!, relative);

  /// Copies a picked image into the receipts folder, returning its relative
  /// path to persist on the transaction.
  Future<String> save(String sourcePath) async {
    await init();
    final String ext =
        p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final String relative = p.join(_folder, '${_uuid.v4()}$ext');
    await File(sourcePath).copy(absolutePath(relative));
    return relative;
  }

  /// Deletes a stored receipt; safe to call if the file is already gone.
  Future<void> delete(String relative) async {
    final File file = File(absolutePath(relative));
    if (await file.exists()) await file.delete();
  }
}
