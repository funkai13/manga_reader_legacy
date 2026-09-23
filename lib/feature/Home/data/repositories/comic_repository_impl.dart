import 'dart:io';

import '../../domain/entity/comic.dart';
import '../../domain/repositories/comic_repository.dart';
import '../datasources/comic_database.dart';
import '../models/comic_fields.dart';
import '../models/comic_model.dart';
import '../services/comic_archive_extractor.dart';
import '../services/comic_storage.dart';

class ComicRepositoryImpl implements ComicRepository {
  final ComicDatabase datasource;
  final ComicStorage storage;
  final ComicArchiveExtractor extractor;

  ComicRepositoryImpl(
    this.datasource, {
    ComicStorage? storage,
    this.extractor = const ComicArchiveExtractor(),
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

  @override
  Future<ComicEntity?> getComicByFilenameMatch(String filename) async =>
      _toEntityOrNull(await datasource.getComicByFilenameMatch(filename));

  /// Extracts the archive first and inserts the row only once the pages are
  /// on disk, so a crash or a bad file never leaves a comic without images.
  /// Metadata the caller didn't provide is taken from ComicInfo.xml.
  @override
  Future<ComicEntity> addComic(ComicEntity comic) async {
    final existingComic = await datasource.getComicByTitle(comic.title);
    if (existingComic != null) return _toEntity(existingComic);

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
      );

      final newId = await datasource.addComic(model);
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

  @override
  Future<void> deleteComic(int id) {
    return datasource.deleteComic(id);
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
