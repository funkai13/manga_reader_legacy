import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Library/data/repositories/library_repository_impl.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockComicDatabase db;
  late LibraryRepositoryImpl repo;

  final rows = <Map<String, dynamic>>[
    {'name': 'Miura', 'count': 1, 'coverPath': '/m.jpg'},
    {'name': 'Oda', 'count': 3, 'coverPath': null},
  ];

  setUp(() {
    db = MockComicDatabase();
    repo = LibraryRepositoryImpl(db);
  });

  group('get categories maps rows to CategoryEntity with the right type', () {
    test('getAuthors', () async {
      when(() => db.getAuthorsWithCount()).thenAnswer((_) async => rows);
      expect(await repo.getAuthors(), [
        CategoryEntity(name: 'Miura', count: 1, type: 'author', coverPath: '/m.jpg'),
        CategoryEntity(name: 'Oda', count: 3, type: 'author'),
      ]);
    });

    test('getGenres', () async {
      when(() => db.getGenresWithCount()).thenAnswer((_) async => rows);
      final result = await repo.getGenres();
      expect(result.map((c) => c.type).toSet(), {'genre'});
      expect(result.map((c) => c.name), ['Miura', 'Oda']);
    });

    test('getCollections', () async {
      when(() => db.getCollectionsWithCount()).thenAnswer((_) async => rows);
      final result = await repo.getCollections();
      expect(result.map((c) => c.type).toSet(), {'collection'});
      expect(result.last.count, 3);
      expect(result.last.coverPath, isNull);
    });

    test('empty result -> empty list', () async {
      when(() => db.getAuthorsWithCount()).thenAnswer((_) async => []);
      expect(await repo.getAuthors(), isEmpty);
    });

    test('malformed row (null name) throws TypeError', () async {
      when(() => db.getGenresWithCount()).thenAnswer((_) async => [
            {'name': null, 'count': 1, 'coverPath': null},
          ]);
      expect(repo.getGenres(), throwsA(isA<TypeError>()));
    });

    test('datasource errors propagate', () async {
      when(() => db.getCollectionsWithCount()).thenThrow(Exception('db'));
      expect(repo.getCollections(), throwsException);
    });
  });

  group('rename delegates to the datasource', () {
    setUp(() {
      when(() => db.updateAuthorName(any(), any())).thenAnswer((_) async {});
      when(() => db.updateGenreName(any(), any())).thenAnswer((_) async {});
      when(() => db.updateCollectionName(any(), any()))
          .thenAnswer((_) async {});
    });

    test('renameAuthor', () async {
      await repo.renameAuthor('a', 'b');
      verify(() => db.updateAuthorName('a', 'b')).called(1);
      verifyNever(() => db.updateGenreName(any(), any()));
    });

    test('renameGenre', () async {
      await repo.renameGenre('a', 'b');
      verify(() => db.updateGenreName('a', 'b')).called(1);
    });

    test('renameCollection', () async {
      await repo.renameCollection('a', 'b');
      verify(() => db.updateCollectionName('a', 'b')).called(1);
    });
  });
}
