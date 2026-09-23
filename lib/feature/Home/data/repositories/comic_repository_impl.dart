import 'dart:developer' as developer;
import 'dart:io';

import 'package:sqflite/sqflite.dart' show DatabaseException;

import '../../domain/entity/comic.dart';
import '../../domain/exceptions/comic_exceptions.dart';
import '../../domain/repositories/comic_repository.dart';
import '../datasources/comic_database.dart';
import '../models/comic_fields.dart';
import '../models/comic_model.dart';
import '../services/comic_archive_extractor.dart';
import '../services/comic_fingerprint.dart';
import '../services/comic_storage.dart';

class ComicRepositoryImpl implements ComicRepository {
  final ComicDatabase datasource;
  final ComicStorage storage;
  final ComicArchiveExtractor extractor;
  final ComicFingerprint fingerprint;

  ComicRepositoryImpl(
    this.datasource, {
    ComicStorage? storage,
    this.extractor = const ComicArchiveExtractor(),
    this.fingerprint = const ComicFingerprint(),
  }) : storage = storage ?? ComicStorage();

  /// Maps a DB row to an entity with paths resolved for this device.
  Future<ComicEntity> _toEntity(ComicModel m) async => ComicEntity(
        id: m.id,
        filePath: m.filePath,
        title: m.title,
        picture: await storage.resolve(m.picture),
        currentReadPage: m.currentReadPage,
        totalPages: m.totalPages,
        lastOpened: m.lastOpened,
        currentReading: m.currentReading,
        imagesPath: await storage.resolve(m.imagesPath),
        isFavorite: m.isFavorite,
        isReading: m.isReading,
        rating: m.rating,
        bookMarks: m.bookMarks,
        isCompleted: m.isCompleted,
        author: m.author,
        genre: m.genre,
        collection: m.collection,
        comicType: m.comicType,
      );

  Future<ComicEntity?> _toEntityOrNull(ComicModel? m) async =>
      m == null ? null : _toEntity(m);

  Future<List<ComicEntity>> _toEntities(List<ComicModel> models) =>
      Future.wait(models.map(_toEntity));

  @override
  Future<ComicEntity?> getComicByPath(String path) async =>
      _toEntityOrNull(await datasource.getComicByPath(path));

  @override
  Future<ComicEntity?> getComicByTitle(String title) async =>
      _toEntityOrNull(await datasource.getComicByTitle(title));

  /// Looks the file up by content. Rows imported before schema v4 have no
  /// hash and are never reported: matching them by name gave false
  /// positives for different comics that share a file name.
  @override
  Future<ComicEntity?> findDuplicate(String filePath) async {
    final hash = await fingerprint.tryOf(filePath);
    if (hash == null) return null;
    return _toEntityOrNull(await datasource.getComicByContentHash(hash));
  }

  /// Extracts the archive first and inserts the row only once the pages are
  /// on disk, so a crash or a bad file never leaves a comic without images.
  /// Metadata the caller didn't provide is taken from ComicInfo.xml.
  ///
  /// Throws [DuplicateComicException] when the same content (by
  /// [ComicFingerprint]) was already imported, whatever the file names.
  @override
  Future<ComicEntity> addComic(ComicEntity comic) async {
    // An unreadable file yields no hash; the extractor then reports it.
    final contentHash = await fingerprint.tryOf(comic.filePath);
    if (contentHash != null) {
      final existing = await datasource.getComicByContentHash(contentHash);
      if (existing != null) {
        throw DuplicateComicException(existingId: existing.id);
      }
    }

    final folder = await storage.newComicFolder();
    try {
      final extracted = await extractor.extract(comic.filePath, folder);
      final info = extracted.info;
      final picture = extracted.thumbnail ?? extracted.pages.first;

      final model = ComicModel(
        id: null,
        filePath: comic.filePath,
        title: comic.title,
        picture: await storage.toStored(picture),
        currentReadPage: comic.currentReadPage,
        totalPages: extracted.pages.length,
        lastOpened: comic.lastOpened,
        currentReading: comic.currentReading,
        imagesPath: await storage.toStored(folder),
        isFavorite: comic.isFavorite,
        isReading: comic.isReading,
        rating: comic.rating,
        bookMarks: comic.bookMarks,
        isCompleted: comic.isCompleted,
        author: _orNull(comic.author) ?? info?.writer,
        genre: _orNull(comic.genre) ?? info?.genre,
        collection: _orNull(comic.collection) ?? info?.series,
        comicType: comic.comicType ?? info?.comicType,
        contentHash: contentHash,
      );

      final int newId;
      try {
        newId = await datasource.addComic(model);
      } on DatabaseException catch (e) {
        // Lost a race with a concurrent import of the same file.
        if (contentHash != null &&
            e.isUniqueConstraintError(
                '${ComicFields.tableName}.${ComicFields.contentHash}')) {
          throw DuplicateComicException();
        }
        rethrow;
      }
      return await _toEntity(
          ComicModel.fromMap({...model.toMap(), ComicFields.id: newId}));
    } catch (_) {
      final dir = Directory(folder);
      if (await dir.exists()) await dir.delete(recursive: true);
      rethrow;
    }
  }

  static String? _orNull(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  @override
  Future<List<ComicEntity>> getAllComics() async =>
      _toEntities(await datasource.fetchAllComics());

  @override
  Future<void> addBookMark(int id, int bookmark) async {
    await datasource.updateBookmark(id, bookmark);
  }

  @override
  Future<void> startReadingComic(int id) async {
    await datasource.updateComic(id: id, isReading: true);
  }

  /// Removes the row, then the extracted pages. A folder that can't be
  /// deleted is only logged: the comic is already gone from the library.
  @override
  Future<void> deleteComic(int id) async {
    final comic = await datasource.getComicById(id);
    await datasource.deleteComic(id);
    if (comic == null) return;
    try {
      await storage.deleteComicFolder(comic.imagesPath);
    } on FileSystemException catch (e) {
      developer.log('Could not delete images of comic $id: $e',
          name: 'ComicRepository');
    }
  }

  @override
  Future<void> updateComicMetadata({
    required int id,
    String? title,
    String? author,
    String? genre,
    String? collection,
    String? comicType,
  }) async {
    await datasource.updateComic(
      id: id,
      title: title,
      author: author,
      genre: genre,
      collection: collection,
      comicType: comicType,
    );
  }

  @override
  Future<List<String>> getDistinctAuthors() async {
    return await datasource.getDistinctValues(ComicFields.author);
  }

  @override
  Future<List<String>> getDistinctGenres() async {
    return await datasource.getDistinctValues(ComicFields.genre);
  }

  @override
  Future<List<String>> getDistinctCollections() async {
    return await datasource.getDistinctValues(ComicFields.collection);
  }

  @override
  Future<List<ComicEntity>> getComicsByAuthor(String author) async =>
      _toEntities(await datasource.getComicsByAuthor(author));

  @override
  Future<List<ComicEntity>> getComicsByGenre(String genre) async =>
      _toEntities(await datasource.getComicsByGenre(genre));

  @override
  Future<List<ComicEntity>> getComicsByCollection(String collection) async =>
      _toEntities(await datasource.getComicsByCollection(collection));
}
