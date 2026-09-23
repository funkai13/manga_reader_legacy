import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:manga_reader/feature/Home/domain/exceptions/comic_exceptions.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_metadata_dialog.dart';

import '../../domain/entity/comic.dart';
import '../../domain/provider/comic_provider.dart';

class ComicController extends AsyncNotifier<List<ComicEntity>> {
  @override
  FutureOr<List<ComicEntity>> build() async {
    final comicRepository = ref.read(comicRepositoryProvider);
    final comics = await comicRepository.getAllComics();
    return comics;
  }

  Future<void> addComic(BuildContext context) async {
    final comicRepository = ref.read(comicRepositoryProvider);

    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.single.path;
      final fileName = result.files.single.name;
      final extension = fileName.split('.').last.toLowerCase();

      if (extension == 'cbr' || extension == 'cbz') {
        if (filePath != null) {
          // 0. Duplicate Check (Title/Filename)
          // First check by exact title (fastest)
          var existingComic = await comicRepository.getComicByTitle(fileName);
          
          // If not found, check if any existing comic has this filename in its path
          // This handles cases where the user renamed the comic in the app
          existingComic ??= await comicRepository.getComicByFilenameMatch(fileName);

          if (existingComic != null) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Este cómic ya está en tu biblioteca.'),
              ),
            );
            return;
          }

          final newComicEntity = ComicEntity(
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
          );
          
          bool isSpinnerOpen = false;
          bool isMetadataOpen = false;
          bool processingFailed = false;

          try {
            // 1. Show loading spinner immediately
            if (!context.mounted) return;
            isSpinnerOpen = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            ).then((_) => isSpinnerOpen = false);

            // 2. Start processing in background with error handling
            final processingFuture = comicRepository
                .addComic(newComicEntity)
                .onError((error, stackTrace) {
              processingFailed = true;
              // Close dialog if open and error occurs
              if (context.mounted && (isSpinnerOpen || isMetadataOpen)) {
                Navigator.of(context).maybePop();
              }
              if (error != null) {
                 throw error;
              } else {
                 throw Exception('Unknown error during processing');
              }
            });

            // 3. Wait a bit to ensure spinner is seen
            await Future.delayed(const Duration(milliseconds: 500));

            // Check if processing already failed
            if (processingFailed) {
              // If failed, the onError callback should have popped the spinner.
              // We just await the future to let the catch block handle the error.
              await processingFuture;
              return;
            }

            // 4. Close spinner and show metadata dialog
            if (!context.mounted) return;
            if (isSpinnerOpen) {
              Navigator.of(context).pop(); // Close spinner
              isSpinnerOpen = false;
            }

            isMetadataOpen = true;
            final dialogFuture = showDialog<Map<String, String>?>(
              context: context,
              barrierDismissible: false,
              builder: (context) => ComicMetadataDialog(fileName: fileName),
            ).then((value) {
              isMetadataOpen = false;
              return value;
            });

            // 5. Wait for both
            final results = await Future.wait([
              processingFuture,
              dialogFuture,
            ], eagerError: false);

            final createdComic = results[0] as ComicEntity;
            final metadata = results[1] as Map<String, String>?;

            // 4. Update metadata if provided
            if (metadata != null) {
              await comicRepository.updateComicMetadata(
                id: createdComic.id!,
                title: metadata['title'],
                author: metadata['author'],
                genre: metadata['genre'],
                collection: metadata['collection'],
                comicType: metadata['comicType'],
              );
            }

            // 5. Update state
            final updatedList = await comicRepository.getAllComics();
            state = AsyncData(updatedList);
          } on UnsupportedComicException catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  e.message.isNotEmpty
                      ? e.message
                      : 'Este archivo de cómic no está soportado.',
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ocurrió un error al agregar el cómic.'),
              ),
            );
          }
        }
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Seleccione un archivo con extensión .cbr o .cbz"),
          ),
        );
      }
    } else {
      // No file selected
    }
  }

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
