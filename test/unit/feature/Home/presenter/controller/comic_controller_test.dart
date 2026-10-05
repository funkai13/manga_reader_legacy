
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/comic_fixtures.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/riverpod_utils.dart';

void main() {
  late MockComicRepository repo;
  late ProviderContainer container;

  final comics = [
    buildComicEntity(id: 1, title: 'A'),
    buildComicEntity(id: 2, title: 'B', isReading: true, currentReadPage: 4),
  ];

  setUpAll(registerCommonFallbacks);

  setUp(() {
    repo = MockComicRepository();
    when(() => repo.getAllComics()).thenAnswer((_) async => comics);
    container = createContainer(comicRepository: repo);
  });

  ComicController notifier() => container.read(comicControllerProvider.notifier);
  AsyncValue<List<ComicEntity>> state() => container.read(comicControllerProvider);

  Future<List<ComicEntity>> loaded() =>
      container.read(comicControllerProvider.future);

  group('build', () {
    test('starts loading then exposes the repository comics', () async {
      final states = recordStates(container, comicControllerProvider);
      expect(states.first, isA<AsyncLoading<List<ComicEntity>>>());

      final data = await loaded();
      expect(data.map((c) => c.title), ['A', 'B']);
      expect(states.last, isA<AsyncData<List<ComicEntity>>>());
      verify(() => repo.getAllComics()).called(1);
    });

    test('repository error -> AsyncError', () async {
      when(() => repo.getAllComics()).thenThrow(Exception('db'));
      await expectLater(loaded(), throwsException);
      expect(state().hasError, isTrue);
      expect(state().error, isA<Exception>());
    });

    test('empty library -> AsyncData([])', () async {
      when(() => repo.getAllComics()).thenAnswer((_) async => []);
      expect(await loaded(), isEmpty);
    });
  });

  group('getAllComics', () {
    test('refreshes state with the latest list', () async {
      await loaded();
      final fresh = [buildComicEntity(id: 3, title: 'C')];
      when(() => repo.getAllComics()).thenAnswer((_) async => fresh);

      final result = await notifier().getAllComics();
      expect(result, fresh);
      expect(state().value, fresh);
    });

    test('on error sets AsyncError and rethrows', () async {
      await loaded();
      when(() => repo.getAllComics()).thenThrow(StateError('boom'));

      await expectLater(notifier().getAllComics(), throwsStateError);
      expect(state().error, isA<StateError>());
    });
  });

  group('updateReadingProgress', () {
    setUp(() {
      when(() => repo.addBookMark(any(), any())).thenAnswer((_) async {});
      when(() => repo.markCompleted(any())).thenAnswer((_) async {});
    });

    test('persists the page and updates only the matching comic', () async {
      await loaded();

      await notifier().updateReadingProgress(1, 7, totalPages: 20);

      verify(() => repo.addBookMark(1, 7)).called(1);
      verifyNever(() => repo.markCompleted(any()));
      final list = state().value!;
      expect(list.firstWhere((c) => c.id == 1).currentReadPage, 7);
      expect(list.firstWhere((c) => c.id == 1).isCompleted, isFalse);
      expect(list.firstWhere((c) => c.id == 2).currentReadPage, 4);
    });

    test('reaching the last page marks the comic as completed', () async {
      await loaded();

      await notifier().updateReadingProgress(2, 19, totalPages: 20);

      verify(() => repo.markCompleted(2)).called(1);
      final comic = state().value!.firstWhere((c) => c.id == 2);
      expect(comic.isCompleted, isTrue);
      expect(comic.currentReadPage, 19);
    });

    test('going back from the end keeps the comic completed', () async {
      await loaded();
      await notifier().updateReadingProgress(2, 19, totalPages: 20);
      await notifier().updateReadingProgress(2, 3, totalPages: 20);
      expect(state().value!.firstWhere((c) => c.id == 2).isCompleted, isTrue);
    });

    test('unknown id leaves the list untouched', () async {
      await loaded();
      await notifier().updateReadingProgress(99, 3, totalPages: 10);
      expect(state().value!.map((c) => c.currentReadPage), [0, 4]);
    });

    test('a repository failure is rethrown and the list is kept', () async {
      await loaded();
      when(() => repo.addBookMark(any(), any()))
          .thenAnswer((_) => Future.error(Exception('write failed')));

      await expectLater(
          notifier().updateReadingProgress(1, 7, totalPages: 20),
          throwsException);
      expect(state().value, comics);
    });
  });

  group('markAsReading', () {
    setUp(() {
      when(() => repo.startReadingComic(any())).thenAnswer((_) async {});
    });

    test('persists and flips isReading for that comic', () async {
      await loaded();
      await notifier().markAsReading(1);

      verify(() => repo.startReadingComic(1)).called(1);
      final list = state().value!;
      expect(list.firstWhere((c) => c.id == 1).isReading, isTrue);
    });

    test('comic already reading keeps the same instance', () async {
      await loaded();
      final before = state().value!.firstWhere((c) => c.id == 2);
      await notifier().markAsReading(2);
      expect(identical(state().value!.firstWhere((c) => c.id == 2), before),
          isTrue);
    });

    test('rethrows repository errors and keeps state', () async {
      await loaded();
      when(() => repo.startReadingComic(any())).thenThrow(Exception('x'));
      await expectLater(notifier().markAsReading(1), throwsException);
      expect(state().value!.first.isReading, isFalse);
    });

    test('while in error state keeps the error', () async {
      when(() => repo.getAllComics()).thenThrow(Exception('db'));
      await expectLater(loaded(), throwsException);
      await notifier().markAsReading(1);
      expect(state().hasError, isTrue);
    });
  });

  group('getSuggestions', () {
    test('author -> distinct authors', () async {
      when(() => repo.getDistinctAuthors()).thenAnswer((_) async => ['Oda']);
      expect(await notifier().getSuggestions('author'), ['Oda']);
    });

    test('collection -> distinct collections', () async {
      when(() => repo.getDistinctCollections())
          .thenAnswer((_) async => ['OP']);
      expect(await notifier().getSuggestions('collection'), ['OP']);
    });

    test('genre -> merges DB genres with predefined ones, dedup + sorted',
        () async {
      when(() => repo.getDistinctGenres())
          .thenAnswer((_) async => ['Shonen', 'Cyberpunk']);

      final genres = await notifier().getSuggestions('genre');

      expect(genres, contains('Cyberpunk'));
      expect(genres.where((g) => g == 'Shonen'), hasLength(1));
      expect(genres, containsAll(['Seinen', 'Isekai', 'Mecha', 'Histórico']));
      expect(genres.length, 21); // 20 predefined + Cyberpunk
      expect(genres, [...genres]..sort());
    });

    test('unknown type -> empty list without hitting repository', () async {
      expect(await notifier().getSuggestions('publisher'), isEmpty);
      verifyNever(() => repo.getDistinctAuthors());
      verifyNever(() => repo.getDistinctGenres());
      verifyNever(() => repo.getDistinctCollections());
    });
  });

  group('updateComicMetadata', () {
    test('persists and reloads the list', () async {
      await loaded();
      when(() => repo.updateComicMetadata(
            id: any(named: 'id'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            genre: any(named: 'genre'),
            collection: any(named: 'collection'),
            comicType: any(named: 'comicType'),
          )).thenAnswer((_) async {});
      final updated = [buildComicEntity(id: 1, title: 'A', comicType: 'Manga')];
      when(() => repo.getAllComics()).thenAnswer((_) async => updated);

      await notifier().updateComicMetadata(id: 1, comicType: 'Manga');

      verify(() => repo.updateComicMetadata(
            id: 1,
            title: null,
            author: null,
            genre: null,
            collection: null,
            comicType: 'Manga',
          )).called(1);
      expect(state().value, updated);
    });

    test('propagates repository errors', () async {
      await loaded();
      when(() => repo.updateComicMetadata(
            id: any(named: 'id'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            genre: any(named: 'genre'),
            collection: any(named: 'collection'),
            comicType: any(named: 'comicType'),
          )).thenThrow(Exception('fail'));
      await expectLater(
          notifier().updateComicMetadata(id: 1, title: 'x'), throwsException);
      expect(state().value, comics);
    });
  });

  group('import', () {
    void stubMetadata() => when(() => repo.updateComicMetadata(
          id: any(named: 'id'),
          title: any(named: 'title'),
          author: any(named: 'author'),
          genre: any(named: 'genre'),
          collection: any(named: 'collection'),
          comicType: any(named: 'comicType'),
        )).thenAnswer((_) async {});

    test('isSupportedArchive accepts .cbz/.cbr in any case', () {
      expect(ComicController.isSupportedArchive('a.cbz'), isTrue);
      expect(ComicController.isSupportedArchive('B.CBR'), isTrue);
      expect(ComicController.isSupportedArchive('c.zip'), isFalse);
      expect(ComicController.isSupportedArchive('cbz'), isFalse);
    });

    test('isAlreadyImported looks the file path up by content', () async {
      when(() => repo.findDuplicate(any())).thenAnswer((_) async => null);
      expect(await notifier().isAlreadyImported('/picked/x.cbz'), isFalse);

      when(() => repo.findDuplicate('/picked/x.cbz'))
          .thenAnswer((_) async => comics.first);
      expect(await notifier().isAlreadyImported('/picked/x.cbz'), isTrue);
      // The title is no longer used to detect duplicates.
      verifyNever(() => repo.getComicByTitle(any()));
    });

    test('importComic sends a fresh entity and does not touch state',
        () async {
      await loaded();
      when(() => repo.addComic(any()))
          .thenAnswer((_) async => comics.first.copyWith(id: 9));

      final created = await notifier().importComic('/tmp/a.cbz', 'a.cbz');

      expect(created.id, 9);
      final sent =
          verify(() => repo.addComic(captureAny())).captured.single as ComicEntity;
      expect(sent.id, isNull);
      expect(sent.title, 'a.cbz');
      expect(sent.filePath, '/tmp/a.cbz');
      expect(sent.comicType, isNull);
      expect(sent.currentReadPage, 0);
      verify(() => repo.getAllComics()).called(1); // only the initial build
    });

    test('finishImport applies trimmed metadata, empty fields as null',
        () async {
      await loaded();
      stubMetadata();

      await notifier().finishImport(comics.first, {
        'title': ' Naruto ',
        'author': '',
        'genre': '  ',
        'collection': 'Naruto',
        'comicType': 'Manga',
      });

      verify(() => repo.updateComicMetadata(
            id: 1,
            title: 'Naruto',
            author: null,
            genre: null,
            collection: 'Naruto',
            comicType: 'Manga',
          )).called(1);
    });

    test('finishImport without metadata only refreshes the list', () async {
      await loaded();
      final added = [...comics, buildComicEntity(id: 3, title: 'C')];
      when(() => repo.getAllComics()).thenAnswer((_) async => added);

      await notifier().finishImport(comics.first, null);

      verifyNever(() => repo.updateComicMetadata(
            id: any(named: 'id'),
            title: any(named: 'title'),
            author: any(named: 'author'),
            genre: any(named: 'genre'),
            collection: any(named: 'collection'),
            comicType: any(named: 'comicType'),
          ));
      expect(state().value!.map((c) => c.title), ['A', 'B', 'C']);
    });
  });

  group('deleteComic', () {
    test('deletes via repository and updates state with remaining comics',
        () async {
      await loaded();
      when(() => repo.deleteComic(1)).thenAnswer((_) async {});
      when(() => repo.getAllComics()).thenAnswer((_) async => [comics[1]]);

      await notifier().deleteComic(1);

      verify(() => repo.deleteComic(1)).called(1);
      expect(state().value!.map((c) => c.title), ['B']);
    });
  });
}
