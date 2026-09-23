import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_file_provider.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_provider.dart';
import 'package:manga_reader/feature/Home/domain/repositories/comic_file_repository.dart';
import 'package:manga_reader/feature/Home/domain/repositories/comic_repository.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_viewer_controller.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
import 'package:manga_reader/feature/Library/domain/providers/library_provider.dart';
import 'package:manga_reader/feature/Library/domain/repositories/library_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockComicRepository extends Mock implements ComicRepository {}

class MockLibraryRepository extends Mock implements LibraryRepository {}

class MockComicFileRepository extends Mock implements ComicFileRepository {}

class _FakeComicEntity extends Fake implements ComicEntity {}

bool _fallbacksRegistered = false;

void registerTestFallbacks() {
  if (_fallbacksRegistered) return;
  registerFallbackValue(_FakeComicEntity());
  _fallbacksRegistered = true;
}

/// Builds a [ComicEntity] with sensible defaults for tests.
ComicEntity buildComic({
  int id = 1,
  String? title,
  String picture = '',
  int currentReadPage = 0,
  int totalPages = 10,
  String? lastOpened,
  String imagesPath = '',
  bool isReading = false,
  bool isFavorite = false,
  bool isCompleted = false,
  String? author,
  String? genre,
  String? collection,
  String? comicType,
}) {
  return ComicEntity(
    id: id,
    title: title ?? 'Comic $id',
    filePath: '/comics/comic_$id.cbz',
    picture: picture,
    currentReadPage: currentReadPage,
    totalPages: totalPages,
    lastOpened: lastOpened ??
        DateTime(2025, 1, 1).add(Duration(days: id)).toIso8601String(),
    currentReading: 0,
    imagesPath: imagesPath,
    isReading: isReading,
    isFavorite: isFavorite,
    bookMarks: '',
    isCompleted: isCompleted,
    author: author,
    genre: genre,
    collection: collection,
    comicType: comicType,
  );
}

/// A representative library: one in progress, one completed, some unread.
List<ComicEntity> sampleComics({String Function(int id)? picture}) => [
      buildComic(
        id: 1,
        title: 'One Piece Vol. 1',
        isReading: true,
        currentReadPage: 4,
        author: 'Eiichiro Oda',
        genre: 'Shonen',
        comicType: 'Manga',
        picture: picture?.call(1) ?? '',
      ),
      buildComic(
        id: 2,
        title: 'Batman: Year One',
        isCompleted: true,
        isReading: true,
        currentReadPage: 9,
        author: 'Frank Miller',
        genre: 'Superhéroes',
        comicType: 'Comic',
        picture: picture?.call(2) ?? '',
      ),
      buildComic(
        id: 3,
        title: 'Akira Vol. 1',
        author: 'Katsuhiro Otomo',
        genre: 'Seinen',
        picture: picture?.call(3) ?? '',
      ),
      buildComic(
        id: 4,
        title: 'Saga Vol. 1',
        genre: 'Ciencia Ficción',
        picture: picture?.call(4) ?? '',
      ),
    ];

List<CategoryEntity> sampleCategories(String type, {String? coverPath}) => [
      CategoryEntity(
          name: 'Eiichiro Oda', count: 3, type: type, coverPath: coverPath),
      CategoryEntity(name: 'Frank Miller', count: 1, type: type),
      CategoryEntity(
          name: 'Katsuhiro Otomo', count: 2, type: type, coverPath: coverPath),
    ];

/// Creates a [MockComicRepository] with every method stubbed to succeed.
MockComicRepository createComicRepository({
  List<ComicEntity> comics = const [],
  Future<List<ComicEntity>> Function()? getAll,
}) {
  registerTestFallbacks();
  final repo = MockComicRepository();
  when(() => repo.getAllComics()).thenAnswer(
      (_) => getAll != null ? getAll() : Future.value(List.of(comics)));
  when(() => repo.getComicByTitle(any())).thenAnswer((_) async => null);
  when(() => repo.getComicByPath(any())).thenAnswer((_) async => null);
  when(() => repo.getComicByFilenameMatch(any())).thenAnswer((_) async => null);
  when(() => repo.addBookMark(any(), any())).thenAnswer((_) async {});
  when(() => repo.startReadingComic(any())).thenAnswer((_) async {});
  when(() => repo.deleteComic(any())).thenAnswer((_) async {});
  when(() => repo.addComic(any())).thenAnswer((inv) async =>
      (inv.positionalArguments.first as ComicEntity).copyWith(id: 99));
  when(() => repo.updateComicMetadata(
        id: any(named: 'id'),
        title: any(named: 'title'),
        author: any(named: 'author'),
        genre: any(named: 'genre'),
        collection: any(named: 'collection'),
        comicType: any(named: 'comicType'),
      )).thenAnswer((_) async {});
  when(() => repo.getDistinctAuthors())
      .thenAnswer((_) async => ['Eiichiro Oda', 'Frank Miller']);
  when(() => repo.getDistinctGenres()).thenAnswer((_) async => ['Shonen']);
  when(() => repo.getDistinctCollections())
      .thenAnswer((_) async => ['One Piece']);
  when(() => repo.getComicsByAuthor(any()))
      .thenAnswer((_) async => List.of(comics));
  when(() => repo.getComicsByGenre(any()))
      .thenAnswer((_) async => List.of(comics));
  when(() => repo.getComicsByCollection(any()))
      .thenAnswer((_) async => List.of(comics));
  return repo;
}

MockLibraryRepository createLibraryRepository({
  List<CategoryEntity>? authors,
  List<CategoryEntity>? genres,
  List<CategoryEntity>? collections,
}) {
  final repo = MockLibraryRepository();
  when(() => repo.getAuthors())
      .thenAnswer((_) async => authors ?? sampleCategories('author'));
  when(() => repo.getGenres())
      .thenAnswer((_) async => genres ?? sampleCategories('genre'));
  when(() => repo.getCollections())
      .thenAnswer((_) async => collections ?? sampleCategories('collection'));
  when(() => repo.renameAuthor(any(), any())).thenAnswer((_) async {});
  when(() => repo.renameGenre(any(), any())).thenAnswer((_) async {});
  when(() => repo.renameCollection(any(), any())).thenAnswer((_) async {});
  return repo;
}

/// Viewer controller that never touches the file system.
class FakeComicViewerController extends ComicViewerController {
  FakeComicViewerController({
    this.images = const [],
    this.error,
    this.neverLoads = false,
  });

  final List<File> images;
  final Object? error;
  final bool neverLoads;
  final List<(String, int)> loadCalls = [];

  @override
  Future<List<File>> build() async => [];

  @override
  Future<void> loadComic(String imagesPath, int comicId) async {
    loadCalls.add((imagesPath, comicId));
    // Let the initial async build() settle first so it does not overwrite
    // the state set below.
    await future;
    state = const AsyncLoading();
    if (neverLoads) return;
    if (error != null) {
      state = AsyncError(error!, StackTrace.empty);
      return;
    }
    state = AsyncData(images);
  }
}

/// Standard provider overrides so no DB / file system is touched.
List<Override> testOverrides({
  ComicRepository? comicRepository,
  LibraryRepository? libraryRepository,
  ComicViewerController Function()? viewerController,
  bool useRealViewerController = false,
}) {
  final fileRepo = MockComicFileRepository();
  when(() => fileRepo.extractComic(any())).thenAnswer((_) async => []);
  return [
    comicRepositoryProvider
        .overrideWithValue(comicRepository ?? createComicRepository()),
    libraryRepositoryProvider
        .overrideWithValue(libraryRepository ?? createLibraryRepository()),
    comicFileRepositoryProvider.overrideWithValue(fileRepo),
    if (!useRealViewerController)
      comicViewerControllerProvider.overrideWith(
        viewerController ?? () => FakeComicViewerController(),
      ),
  ];
}

/// Fake [FilePicker] returning a predefined result.
class FakeFilePicker extends FilePicker {
  FakeFilePicker(this.result);

  FilePickerResult? result;
  int calls = 0;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    return result;
  }
}

FilePickerResult pickedFile(String name, {String? path}) => FilePickerResult([
      PlatformFile(name: name, path: path ?? '/fake/$name', size: 10),
    ]);

/// Mocks the `vibration` plugin channel so long-press does not throw.
void mockVibrationChannel(WidgetTester tester, {bool hasVibrator = false}) {
  const channel = MethodChannel('vibration');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
      (call) async {
    if (call.method == 'hasVibrator') return hasVibrator;
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, null));
}

/// Completer-backed future that never completes (loading state).
Future<List<T>> neverCompletes<T>() => Completer<List<T>>().future;
