import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../domain/entity/comic.dart';
import '../../domain/provider/comic_provider.dart';

class ComicController extends AsyncNotifier<List<ComicEntity>> {
  @override
  FutureOr<List<ComicEntity>> build() async {
    final comicRepository = ref.read(comicRepositoryProvider);
    final comics = await comicRepository.getAllComics();
    return comics;
  }

  static bool isSupportedArchive(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    return extension == '.cbz' || extension == '.cbr';
  }

  /// Whether a comic with this file name was already imported: by title, or
  /// by file name when the user renamed the comic in the app.
  Future<bool> isAlreadyImported(String fileName) async {
    final comicRepository = ref.read(comicRepositoryProvider);
    return await comicRepository.getComicByTitle(fileName) != null ||
        await comicRepository.getComicByFilenameMatch(fileName) != null;
  }

  /// Extracts and stores the comic. The list is refreshed by [finishImport]
  /// once the user is done with the metadata dialog.
  Future<ComicEntity> importComic(String filePath, String fileName) {
    return ref.read(comicRepositoryProvider).addComic(
          ComicEntity(
            filePath: filePath,
            title: fileName,
            currentReadPage: 0,
            totalPages: 0,
            picture: '',
            lastOpened: DateTime.now().toIso8601String(),
            currentReading: 0,
            imagesPath: '',
            isReading: false,
            isFavorite: false,
            rating: null,
            bookMarks: '',
            isCompleted: false,
          ),
        );
  }

  /// Applies the metadata the user entered (empty fields keep what the
  /// archive's ComicInfo.xml provided) and refreshes the list.
  Future<void> finishImport(
    ComicEntity created,
    Map<String, String>? metadata,
  ) async {
    final comicRepository = ref.read(comicRepositoryProvider);
    if (metadata != null) {
      await comicRepository.updateComicMetadata(
        id: created.id!,
        title: _nonEmpty(metadata['title']),
        author: _nonEmpty(metadata['author']),
        genre: _nonEmpty(metadata['genre']),
        collection: _nonEmpty(metadata['collection']),
        comicType: metadata['comicType'],
      );
    }
    final comics = await comicRepository.getAllComics();
    if (ref.mounted) state = AsyncData(comics);
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  Future<List<ComicEntity>> getAllComics() async {
    final comicRepository = ref.read(comicRepositoryProvider);
    try {
      final comics = await comicRepository.getAllComics();
      state = AsyncData(comics);
      return comics;
    } catch (error) {
      state = AsyncError(error, StackTrace.current);
      rethrow;
    }
  }

  Future<String> createBookmark(int id, int bookMark, ComicEntity comic) async {
    final comicRepository = ref.read(comicRepositoryProvider);
    try {
      await comicRepository.addBookMark(id, bookMark);
      state = state.whenData((comics) {
        return comics.map((c) {
          if (c.id == id) {
            return c.copyWith(currentReadPage: bookMark);
          }
          return c;
        }).toList();
      });

      return 'Update success';
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> markAsReading(int id) async {
    final comicRepository = ref.read(comicRepositoryProvider);
    try {
      await comicRepository.startReadingComic(id);

      state = state.whenData((comics) {
        return comics.map((c) {
          if (c.id == id && !c.isReading) {
            return c.copyWith(isReading: true);
          }
          return c;
        }).toList();
      });
    } catch (error) {
      rethrow;
    }
  }

  Future<List<String>> getSuggestions(String type) async {
    final comicRepository = ref.read(comicRepositoryProvider);
    switch (type) {
      case 'author':
        return await comicRepository.getDistinctAuthors();
      case 'genre':
        final existingGenres = await comicRepository.getDistinctGenres();
        final predefinedGenres = [
          'Shonen',
          'Seinen',
          'Shojo',
          'Josei',
          'Kodomo',
          'Isekai',
          'Fantasía',
          'Acción',
          'Aventura',
          'Comedia',
          'Drama',
          'Romance',
          'Ciencia Ficción',
          'Terror',
          'Misterio',
          'Slice of Life',
          'Deportes',
          'Mecha',
          'Superhéroes',
          'Histórico',
        ];
        // Combine and remove duplicates
        final allGenres = {...existingGenres, ...predefinedGenres}.toList();
        allGenres.sort();
        return allGenres;
      case 'collection':
        return await comicRepository.getDistinctCollections();
      default:
        return [];
    }
  }

  Future<void> updateComicMetadata({
    required int id,
    String? title,
    String? author,
    String? genre,
    String? collection,
    String? comicType,
  }) async {
    final comicRepository = ref.read(comicRepositoryProvider);
    await comicRepository.updateComicMetadata(
      id: id,
      title: title,
      author: author,
      genre: genre,
      collection: collection,
      comicType: comicType,
    );
    // Refresh the list
    final updatedList = await comicRepository.getAllComics();
    state = AsyncData(updatedList);
  }
}

final comicControllerProvider =
    AsyncNotifierProvider<ComicController, List<ComicEntity>>(
  ComicController.new,
);
