import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/comic.dart';
import '../models/reading_mode.dart';
import 'archive/archive_service.dart';
import 'database/comic_database.dart';
import 'storage/comic_storage.dart';

class ComicRepository {
  final ComicDatabase _db;
  final ArchiveService _archiveService;
  final ComicStorage _storage;

  ComicRepository({
    ComicDatabase? database,
    ArchiveService? archiveService,
    ComicStorage? storage,
  })  : _db = database ?? ComicDatabase.instance,
        _archiveService = archiveService ?? const ArchiveService(),
        _storage = storage ?? ComicStorage();

  Future<Comic> _resolvePaths(Comic comic) async {
    final resolvedImages = await _storage.resolve(comic.imagesPath);
    final resolvedPicture = await _storage.resolveNullable(comic.picture);
    return comic.copyWith(
      imagesPath: resolvedImages,
      picture: resolvedPicture,
    );
  }

  Future<List<Comic>> getAllComics() async {
    final rawComics = await _db.getAllComics();
    final resolved = <Comic>[];
    for (final c in rawComics) {
      resolved.add(await _resolvePaths(c));
    }
    return resolved;
  }

  Future<Comic?> getComicById(int id) async {
    final raw = await _db.getComicById(id);
    if (raw == null) return null;
    return await _resolvePaths(raw);
  }

  Future<Comic?> getComicByHash(String hash) async {
    final raw = await _db.getComicByHash(hash);
    if (raw == null) return null;
    return await _resolvePaths(raw);
  }

  Future<Comic> importComic(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const ArchiveException('No se encontró el archivo seleccionado.');
    }

    final hash = await _archiveService.calculateFingerprint(filePath);
    final existing = await getComicByHash(hash);
    if (existing != null) {
      return existing;
    }

    final outputFolder = await _storage.newComicFolder();
    final extracted = await _archiveService.extract(filePath, outputFolder);

    final info = extracted.info;
    final fallbackTitle = p.basenameWithoutExtension(filePath);
    final title = (info?.title != null && info!.title!.isNotEmpty) ? info.title! : fallbackTitle;
    final readingMode = (info?.isRightToLeft ?? true)
        ? ReadingMode.rightToLeft
        : ReadingMode.leftToRight;

    final storedImages = await _storage.toStored(outputFolder);
    final storedCover = extracted.coverPath != null
        ? await _storage.toStored(extracted.coverPath!)
        : null;

    final newComic = Comic(
      title: title,
      filePath: filePath,
      imagesPath: storedImages,
      picture: storedCover,
      currentPage: 0,
      totalPages: extracted.pages.length,
      lastOpened: DateTime.now().toIso8601String(),
      isReading: false,
      isCompleted: false,
      isFavorite: false,
      author: info?.writer,
      genre: info?.genre,
      collection: info?.series,
      comicType: readingMode,
      contentHash: hash,
      summary: info?.summary,
      volume: info?.volume,
      fileSize: extracted.fileSize,
    );

    final id = await _db.insertComic(newComic);
    return (await getComicById(id))!;
  }

  Future<void> updateProgress(
    int id,
    int currentPage, {
    bool? isReading,
    bool? isCompleted,
  }) async {
    await _db.updateProgress(
      id,
      currentPage,
      isReading: isReading,
      isCompleted: isCompleted,
      lastOpened: DateTime.now().toIso8601String(),
    );
  }

  Future<void> setActiveReading(int id) async {
    await _db.setActiveReading(id);
  }

  Future<void> deleteComic(Comic comic) async {
    if (comic.id != null) {
      await _db.deleteComic(comic.id!);
    }
    await _storage.deleteComicFolder(comic.imagesPath);
  }

  Future<List<Map<String, dynamic>>> getCollectionsWithCount() =>
      _db.getCollectionsWithCount();

  Future<List<Map<String, dynamic>>> getAuthorsWithCount() =>
      _db.getAuthorsWithCount();

  Future<List<Map<String, dynamic>>> getGenresWithCount() =>
      _db.getGenresWithCount();

  Future<List<Comic>> getComicsByCollection(String collection) async {
    final raw = await _db.getComicsByCollection(collection);
    final resolved = <Comic>[];
    for (final c in raw) {
      resolved.add(await _resolvePaths(c));
    }
    return resolved;
  }
}
