import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
import 'package:manga_reader/feature/Library/presenter/controller/library_controller.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/comic_fixtures.dart';
import '../../../../helpers/mocks.dart';
import '../../../../helpers/riverpod_utils.dart';

void main() {
  late MockLibraryRepository repo;
  late MockComicRepository comicRepo;
  late ProviderContainer container;

  final authors = [CategoryEntity(name: 'Oda', count: 2, type: 'author')];
  final genres = [CategoryEntity(name: 'Seinen', count: 1, type: 'genre')];
  final collections = [
    CategoryEntity(name: 'OP', count: 5, type: 'collection', coverPath: '/c')
  ];

  setUp(() {
    repo = MockLibraryRepository();
    when(() => repo.getAuthors()).thenAnswer((_) async => authors);
    when(() => repo.getGenres()).thenAnswer((_) async => genres);
    when(() => repo.getCollections()).thenAnswer((_) async => collections);
    when(() => repo.renameAuthor(any(), any())).thenAnswer((_) async {});
    when(() => repo.renameGenre(any(), any())).thenAnswer((_) async {});
    when(() => repo.renameCollection(any(), any())).thenAnswer((_) async {});
    comicRepo = MockComicRepository();
    when(() => comicRepo.getAllComics()).thenAnswer((_) async => []);
    when(() => comicRepo.getComicsByAuthor(any()))
        .thenAnswer((_) async => [buildComicEntity(id: 1)]);
    container =
        createContainer(libraryRepository: repo, comicRepository: comicRepo);
  });

  /// The provider is autoDispose: keep it alive during the test.
  Future<List<CategoryEntity>> load(String type) {
    container.listen(libraryControllerProvider(type), (_, __) {});
    return container.read(libraryControllerProvider(type).future);
  }

  group('build(type)', () {
    test('author', () async {
      expect(await load('author'), authors);
      verify(() => repo.getAuthors()).called(1);
    });

    test('genre', () async {
      expect(await load('genre'), genres);
    });

    test('collection', () async {
      expect(await load('collection'), collections);
    });

    test('unknown type -> [] without hitting the repository', () async {
      expect(await load('publisher'), isEmpty);
      verifyNever(() => repo.getAuthors());
      verifyNever(() => repo.getGenres());
      verifyNever(() => repo.getCollections());
    });

    test('each type is an independent family member', () async {
      await load('author');
      await load('genre');
      expect(container.read(libraryControllerProvider('author')).value, authors);
      expect(container.read(libraryControllerProvider('genre')).value, genres);
    });

    test('loading -> data transition', () async {
      final completer = Completer<List<CategoryEntity>>();
      when(() => repo.getAuthors()).thenAnswer((_) => completer.future);
      final states = recordStates(container, libraryControllerProvider('author'));

      expect(states.single.isLoading, isTrue);
      completer.complete(authors);
      await container.read(libraryControllerProvider('author').future);
      expect(states.last.value, authors);
    });

    test('repository error -> AsyncError', () async {
      when(() => repo.getGenres()).thenThrow(Exception('db'));
      await expectLater(load('genre'), throwsException);
      expect(container.read(libraryControllerProvider('genre')).hasError, isTrue);
    });
  });

  group('filteredComicsProvider', () {
    test('is autoDispose: re-fetched once nobody listens', () async {
      const filter = (type: 'author', value: 'Oda');
      final sub = container.listen(filteredComicsProvider(filter), (_, __) {});
      expect(await container.read(filteredComicsProvider(filter).future),
          hasLength(1));
      sub.close();
      await container.pump();
      expect(container.exists(filteredComicsProvider(filter)), isFalse);
    });
  });

  group('renameCategory', () {
    test('author: renames and reloads', () async {
      await load('author');
      final renamed = [CategoryEntity(name: 'E. Oda', count: 2, type: 'author')];
      when(() => repo.getAuthors()).thenAnswer((_) async => renamed);

      await container
          .read(libraryControllerProvider('author').notifier)
          .renameCategory('Oda', 'E. Oda', 'author');

      verify(() => repo.renameAuthor('Oda', 'E. Oda')).called(1);
      expect(await container.read(libraryControllerProvider('author').future),
          renamed);
    });

    test('genre and collection call the matching repository method',
        () async {
      await load('genre');
      final notifier =
          container.read(libraryControllerProvider('genre').notifier);
      await notifier.renameCategory('a', 'b', 'genre');
      await notifier.renameCategory('c', 'd', 'collection');
      verify(() => repo.renameGenre('a', 'b')).called(1);
      verify(() => repo.renameCollection('c', 'd')).called(1);
      verifyNever(() => repo.renameAuthor(any(), any()));
    });

    test('unknown type renames nothing but still refreshes', () async {
      await load('author');
      await container
          .read(libraryControllerProvider('author').notifier)
          .renameCategory('a', 'b', 'publisher');
      verifyNever(() => repo.renameAuthor(any(), any()));
      verifyNever(() => repo.renameGenre(any(), any()));
      verifyNever(() => repo.renameCollection(any(), any()));
      await container.read(libraryControllerProvider('author').future);
      verify(() => repo.getAuthors()).called(2);
    });

    test('refreshes Home and the filtered lists after renaming', () async {
      await load('author');
      container.listen(comicControllerProvider, (_, __) {});
      await container.read(comicControllerProvider.future);
      const filter = (type: 'author', value: 'Oda');
      container.listen(filteredComicsProvider(filter), (_, __) {});
      await container.read(filteredComicsProvider(filter).future);

      await container
          .read(libraryControllerProvider('author').notifier)
          .renameCategory('Oda', 'E. Oda', 'author');
      await container.read(comicControllerProvider.future);
      await container.read(filteredComicsProvider(filter).future);

      verify(() => comicRepo.getAllComics()).called(2);
      verify(() => comicRepo.getComicsByAuthor('Oda')).called(2);
    });

    test('does not touch a disposed notifier after the rename finishes',
        () async {
      final sub =
          container.listen(libraryControllerProvider('author'), (_, __) {});
      await container.read(libraryControllerProvider('author').future);
      final renaming = Completer<void>();
      when(() => repo.renameAuthor(any(), any()))
          .thenAnswer((_) => renaming.future);

      final future = container
          .read(libraryControllerProvider('author').notifier)
          .renameCategory('Oda', 'E. Oda', 'author');
      sub.close(); // e.g. the user left the screen
      await container.pump();
      renaming.complete();

      await expectLater(future, completes);
      verify(() => repo.renameAuthor('Oda', 'E. Oda')).called(1);
    });

    test('rethrows repository errors', () async {
      await load('author');
      when(() => repo.renameAuthor(any(), any())).thenThrow(Exception('x'));
      await expectLater(
        container
            .read(libraryControllerProvider('author').notifier)
            .renameCategory('a', 'b', 'author'),
        throwsException,
      );
    });
  });
}
