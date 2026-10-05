import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../domain/entity/comic.dart';
import '../../domain/provider/comic_provider.dart';
import '../../domain/repositories/comic_repository.dart';

class ComicController extends AsyncNotifier<List<ComicEntity>> {
  late ComicRepository _comicRepository;

  @override
  FutureOr<List<ComicEntity>> build() async {
    _comicRepository = ref.read(comicRepositoryProvider);
    final comics = await _comicRepository.getAllComics();
    return comics;
  }

  static bool isSupportedArchive(String fileName) {
    final extension = p.extension(fileName).toLowerCase();
    return extension == '.cbz' || extension == '.cbr';
  }

  /// Whether the file at [filePath] was already imported, compared by
  /// content: renamed files are still detected and different comics that
  /// share a file name are not.
  Future<bool> isAlreadyImported(String filePath) async {
    return await _comicRepository.findDuplicate(filePath) != null;
  }

  /// Extracts and stores the comic. The list is refreshed by [finishImport]
  /// once the user is done with the metadata dialog.
  Future<ComicEntity> importComic(String filePath, String fileName) {
    return _comicRepository.addComic(
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
    if (metadata != null) {
      await _comicRepository.updateComicMetadata(
        id: created.id!,
        title: _nonEmpty(metadata['title']),
        author: _nonEmpty(metadata['author']),
        genre: _nonEmpty(metadata['genre']),
        collection: _nonEmpty(metadata['collection']),
        comicType: metadata['comicType'],
      );
    }
    final comics = await _comicRepository.getAllComics();
    if (ref.mounted) state = AsyncData(comics);
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value.trim();

  Future<List<ComicEntity>> getAllComics() async {
    try {
      final comics = await _comicRepository.getAllComics();
      if (ref.mounted) state = AsyncData(comics);
      return comics;
    } catch (error) {
      if (ref.mounted) state = AsyncError(error, StackTrace.current);
      rethrow;
    }
  }

  /// Saves the page being read; reaching the last page marks the comic as
  /// completed so it leaves "Continuar Leyendo".
  Future<void> updateReadingProgress(
    int id,
    int page, {
    required int totalPages,
  }) async {
    await _comicRepository.addBookMark(id, page);
    final finished = totalPages > 0 && page >= totalPages - 1;
    if (finished) await _comicRepository.markCompleted(id);

    if (!ref.mounted) return;
    state = state.whenData((comics) => [
          for (final c in comics)
            if (c.id == id)
              c.copyWith(
                currentReadPage: page,
                isCompleted: c.isCompleted || finished,
              )
            else
              c,
        ]);
  }

  Future<void> markAsReading(int id) async {
    try {
      await _comicRepository.startReadingComic(id);

      if (!ref.mounted) return;
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
    switch (type) {
      case 'author':
        return await _comicRepository.getDistinctAuthors();
      case 'genre':
        final existingGenres = await _comicRepository.getDistinctGenres();
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
        return await _comicRepository.getDistinctCollections();
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
    await _comicRepository.updateComicMetadata(
      id: id,
      title: title,
      author: author,
      genre: genre,
      collection: collection,
      comicType: comicType,
    );
    if (!ref.mounted) return;
    // Refresh the list
    final updatedList = await _comicRepository.getAllComics();
    if (!ref.mounted) return;
    state = AsyncData(updatedList);
  }

  Future<void> deleteComic(int id) async {
    await _comicRepository.deleteComic(id);
    if (!ref.mounted) return;
    final updatedList = await _comicRepository.getAllComics();
    if (!ref.mounted) return;
    state = AsyncData(updatedList);
  }
}

final comicControllerProvider =
    AsyncNotifierProvider<ComicController, List<ComicEntity>>(
  ComicController.new,
);
