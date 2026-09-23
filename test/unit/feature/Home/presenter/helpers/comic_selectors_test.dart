import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Home/presenter/helpers/comic_selectors.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/comic_fixtures.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/riverpod_utils.dart';

void main() {
  late MockComicRepository repo;

  setUp(() => repo = MockComicRepository());

  Future<ProviderContainer> withComics(List<ComicEntity> comics) async {
    when(() => repo.getAllComics()).thenAnswer((_) async => comics);
    final container = createContainer(comicRepository: repo);
    await container.read(comicControllerProvider.future);
    return container;
  }

  group('lastAddedComicsProvider', () {
    test('empty while loading', () {
      final completer = Completer<List<ComicEntity>>();
      when(() => repo.getAllComics()).thenAnswer((_) => completer.future);
      final container = createContainer(comicRepository: repo);
      expect(container.read(lastAddedComicsProvider), isEmpty);
    });

    test('empty on error', () async {
      when(() => repo.getAllComics()).thenThrow(Exception('x'));
      final container = createContainer(comicRepository: repo);
      await expectLater(
          container.read(comicControllerProvider.future), throwsException);
      expect(container.read(lastAddedComicsProvider), isEmpty);
    });

    test('sorts by id desc (newest imported first) and takes 6', () async {
      final comics = [
        for (var i = 1; i <= 8; i++)
          buildComicEntity(
              // lastOpened must not affect the order.
              id: i,
              lastOpened: DateTime(2025, 1, 9 - i).toIso8601String()),
      ]..shuffle();
      final c = await withComics(comics);
      expect(
          c.read(lastAddedComicsProvider).map((e) => e.id), [8, 7, 6, 5, 4, 3]);
    });

    test('fewer than 6 returns all', () async {
      final c = await withComics([
        buildComicEntity(id: 1, lastOpened: '2025-03-01T00:00:00'),
        buildComicEntity(id: 2, lastOpened: '2025-01-01T00:00:00'),
      ]);
      expect(c.read(lastAddedComicsProvider).map((e) => e.id), [2, 1]);
    });

    test('is not the same list as "Continuar Leyendo"', () async {
      final c = await withComics([
        buildComicEntity(
            id: 1, isReading: true, lastOpened: '2025-06-01T00:00:00'),
        buildComicEntity(id: 2, lastOpened: '2025-01-01T00:00:00'),
      ]);
      expect(c.read(lastAddedComicsProvider).first.id, 2);
    });

    test('comics without id go last', () async {
      final c = await withComics([
        buildComicEntity(id: null),
        buildComicEntity(id: 2),
      ]);
      expect(c.read(lastAddedComicsProvider).first.id, 2);
    });
  });

  group('readingNowComicsProvider', () {
    test('only reading and not completed', () async {
      final c = await withComics([
        buildComicEntity(id: 1, isReading: true),
        buildComicEntity(id: 2, isReading: true, isCompleted: true),
        buildComicEntity(id: 3),
        buildComicEntity(id: 4, isCompleted: true),
      ]);
      expect(c.read(readingNowComicsProvider).map((e) => e.id), [1]);
    });

    test('reacts to markAsReading', () async {
      when(() => repo.startReadingComic(any())).thenAnswer((_) async {});
      final c = await withComics([buildComicEntity(id: 1)]);
      expect(c.read(readingNowComicsProvider), isEmpty);

      await c.read(comicControllerProvider.notifier).markAsReading(1);
      expect(c.read(readingNowComicsProvider).map((e) => e.id), [1]);
      expect(c.read(unreadComicsProvider), isEmpty);
    });
  });

  group('unreadComicsProvider', () {
    test('page 0, not reading and not completed', () async {
      final c = await withComics([
        buildComicEntity(id: 1),
        buildComicEntity(id: 2, currentReadPage: 3),
        buildComicEntity(id: 3, isReading: true),
        buildComicEntity(id: 4, isCompleted: true),
      ]);
      expect(c.read(unreadComicsProvider).map((e) => e.id), [1]);
    });

    test('empty library', () async {
      final c = await withComics([]);
      expect(c.read(unreadComicsProvider), isEmpty);
      expect(c.read(readingNowComicsProvider), isEmpty);
      expect(c.read(lastAddedComicsProvider), isEmpty);
    });
  });
}
