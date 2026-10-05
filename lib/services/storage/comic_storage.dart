import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where extracted comics live, and how their paths are stored in the DB.
///
/// Paths are stored relative to the app documents directory because on iOS
/// and Android sandboxes its absolute location can change after app updates or restores.
class ComicStorage {
  ComicStorage({Future<Directory> Function()? documentsDirectory})
      : _documentsDirectory = documentsDirectory ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _documentsDirectory;
  Future<String>? _documentsPath;

  Future<String> get documentsPath => _documentsPath ??= _documentsDirectory().then((d) => d.path);

  /// Folder under which every imported comic gets its own sub-folder.
  Future<String> get comicsRoot async => p.join(await documentsPath, 'comics');

  /// Returns a new folder path for a comic being imported.
  Future<String> newComicFolder() async => p.join(
        await comicsRoot,
        'c_${DateTime.now().microsecondsSinceEpoch}',
      );

  /// Deletes the images folder of a comic ([storedPath] as kept in the DB).
  Future<bool> deleteComicFolder(String storedPath) async {
    if (storedPath.isEmpty) return false;
    final folder = p.normalize(await resolve(storedPath));
    if (!p.isWithin(await comicsRoot, folder)) return false;
    final dir = Directory(folder);
    if (!await dir.exists()) return false;
    await dir.delete(recursive: true);
    return true;
  }

  /// Converts an absolute path under the documents directory to the portable
  /// form stored in the DB (relative, posix style).
  Future<String> toStored(String absolutePath) async {
    final docs = await documentsPath;
    if (absolutePath.isEmpty || !p.isWithin(docs, absolutePath)) {
      return absolutePath;
    }
    return p.posix.joinAll(p.split(p.relative(absolutePath, from: docs)));
  }

  /// Converts a stored path back to an absolute one for this device.
  Future<String> resolve(String storedPath) async {
    if (storedPath.isEmpty || p.isAbsolute(storedPath)) return storedPath;
    return p.joinAll([await documentsPath, ...p.posix.split(storedPath)]);
  }

  Future<String?> resolveNullable(String? storedPath) async =>
      storedPath == null ? null : resolve(storedPath);
}
