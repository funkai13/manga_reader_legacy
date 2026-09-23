
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

  group('createBookmark', () {
    test('persists the page and updates only the matching comic', () async {
      await loaded();
      when(() => repo.addBookMark(any(), any())).thenAnswer((_) async {});

      final msg = await notifier().createBookmark(1, 7, comics.first);

      expect(msg, 'Update success');
      verify(() => repo.addBookMark(1, 7)).called(1);
      final list = state().value!;
      expect(list.firstWhere((c) => c.id == 1).currentReadPage, 7);
      expect(list.firstWhere((c) => c.id == 2).currentReadPage, 4);
    });

    test('unknown id leaves the list untouched', () async {
      await loaded();
      when(() => repo.addBookMark(any(), any())).thenAnswer((_) async {});
      await notifier().createBookmark(99, 3, comics.first);
      expect(state().value!.map((c) => c.currentReadPage), [0, 4]);
    });

    test(
      'repository failure is reported (AsyncError / rethrow)',
      () async {
        await loaded();
        when(() => repo.addBookMark(any(), any()))
            .thenAnswer((_) => Future.error(Exception('write failed')));

        await expectLater(
            notifier().createBookmark(1, 7, comics.first), throwsException);
        expect(state().hasError, isTrue);
      },
    );
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
}
