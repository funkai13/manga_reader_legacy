import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
import 'package:manga_reader/feature/Home/data/models/comic_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/archive_builder.dart';
import '../../../../helpers/comic_fixtures.dart';
import '../../../../helpers/sqflite_test_setup.dart';

void main() {
  late Directory dbDir;
  final db = ComicDatabase.instance;

  setUpAll(() async {
    dbDir = createTempDir('comic_db_test_');
    await setUpSqfliteFfi(dbDir);
  });

  tearDownAll(() async {
    (await db.database).close();
    deleteQuietly(dbDir);
  });

  setUp(clearComicsTable);

  Future<int> insert({
    String title = 'Comic',
    String filePath = '/comics/comic.cbz',
    String? author,
    String? genre,
    String? collection,
    String picture = '',
    String? comicType,
    String? contentHash,
  }) {
    return db.addComic(ComicModel.fromMap({
      ...buildComicModel(
        id: null,
        title: title,
        filePath: filePath,
        author: author,
        genre: genre,
        collection: collection,
        picture: picture,
        comicType: comicType,
      ).toMap(),
      ComicFields.contentHash: contentHash,
    }));
  }

  group('database setup', () {
    test('instance is a singleton', () {
      expect(identical(ComicDatabase.instance, db), isTrue);
    });

    test('database getter caches the same connection', () async {
      final a = await db.database;
      final b = await db.database;
      expect(identical(a, b), isTrue);
    });

    test('creates comics.db at version 4 with the full schema', () async {
      final database = await db.database;
      expect(p.normalize(database.path),
          p.normalize(p.join(dbDir.path, 'comics.db')));
      expect(await database.getVersion(), 4);

      final cols = await database
          .rawQuery('PRAGMA table_info(${ComicFields.tableName})');
      final names = cols.map((c) => c['name']).toSet();
      expect(names, {
        ComicFields.id,
        ComicFields.filePath,
        ComicFields.title,
        ComicFields.picture,
        ComicFields.currentPage,
        ComicFields.totalPages,
        ComicFields.lastOpened,
        ComicFields.currentReading,
        ComicFields.imagesPath,
        ComicFields.isReading,
        ComicFields.isFavorite,
        ComicFields.bookMarks,
        ComicFields.rating,
        ComicFields.isCompleted,
        ComicFields.author,
        ComicFields.genre,
        ComicFields.collection,
        ComicFields.comicType,
        ComicFields.contentHash,
      });
    });

    test('creates the lookup indexes (contentHash unique)', () async {
      final database = await db.database;
      final indexes = {
        for (final row in await database
            .rawQuery('PRAGMA index_list(${ComicFields.tableName})'))
          row['name'] as String: row['unique'] as int,
      };
      expect(indexes, containsPair('idx_comics_contentHash', 1));
      for (final column in [
        ComicFields.author,
        ComicFields.genre,
        ComicFields.collection,
        ComicFields.filePath,
      ]) {
        expect(indexes, containsPair('idx_comics_$column', 0));
      }
    });
  });

  group('addComic / fetchAllComics', () {
    test('empty table returns empty list', () async {
      expect(await db.fetchAllComics(), isEmpty);
    });

    test('insert returns auto-increment ids and data roundtrips', () async {
      final id1 = await insert(title: 'A', author: 'Oda', comicType: 'Manga');
      final id2 = await insert(title: 'B');
      expect(id2, greaterThan(id1));

      final all = await db.fetchAllComics();
      expect(all.map((c) => c.title), ['B', 'A']);
      final a = all.last;
      expect(a.id, id1);
      expect(a.author, 'Oda');
      expect(a.comicType, 'Manga');
      expect(a.isFavorite, isFalse);
      expect(a.rating, isNull);
    });

    test('fetchAllComics returns newest first (by id), whatever the titles',
        () async {
      await insert(title: 'b');
      await insert(title: 'C');
      await insert(title: 'a');
      expect((await db.fetchAllComics()).map((c) => c.title), ['a', 'C', 'b']);
    });

    test('insert trims title and categories', () async {
      await insert(
          title: '  One Piece 1.cbz ',
          author: ' Oda ',
          genre: 'Shonen\t',
          collection: '\nOne Piece');
      final c = (await db.fetchAllComics()).single;
      expect(c.title, 'One Piece 1.cbz');
      expect(c.author, 'Oda');
      expect(c.genre, 'Shonen');
      expect(c.collection, 'One Piece');
    });

    test('contentHash roundtrips; duplicates violate the UNIQUE index',
        () async {
      final id = await insert(title: 'A', contentHash: 'abc');
      expect((await db.getComicByContentHash('abc'))!.id, id);
      expect((await db.getComicByContentHash('abc'))!.contentHash, 'abc');
      expect(await db.getComicByContentHash('zzz'), isNull);

      await expectLater(
        insert(title: 'B', contentHash: 'abc'),
        throwsA(isA<DatabaseException>().having(
            (e) => e.isUniqueConstraintError(
                '${ComicFields.tableName}.${ComicFields.contentHash}'),
            'unique contentHash',
            isTrue)),
      );
    });

    test('many legacy rows without contentHash are allowed', () async {
      await insert(title: 'A');
      await insert(title: 'B');
      expect(await db.fetchAllComics(), hasLength(2));
    });

    test('getComicById', () async {
      final id = await insert(title: 'X');
      expect((await db.getComicById(id))!.title, 'X');
      expect(await db.getComicById(id + 100), isNull);
    });

    test('ignores provided id=null and generates a new one', () async {
      final id = await insert();
      expect(id, isPositive);
    });

    test('inserting a duplicate explicit id throws', () async {
      await db.addComic(buildComicModel(id: 42));
      expect(() => db.addComic(buildComicModel(id: 42)), throwsA(anything));
    });

    test('booleans and rating are persisted', () async {
      await db.addComic(buildComicModel(
        id: null,
        isFavorite: true,
        isReading: true,
        isCompleted: true,
        rating: 4,
      ));
      final c = (await db.fetchAllComics()).single;
      expect(c.isFavorite, isTrue);
      expect(c.isReading, isTrue);
      expect(c.isCompleted, isTrue);
      expect(c.rating, 4);
    });
  });

  group('lookups', () {
    test('getComicByPath / getComicByFilePath', () async {
      final id = await insert(filePath: '/x/one.cbz');
      expect((await db.getComicByPath('/x/one.cbz'))!.id, id);
      expect((await db.getComicByFilePath('/x/one.cbz'))!.id, id);
      expect(await db.getComicByPath('/x/none.cbz'), isNull);
      expect(await db.getComicByFilePath('/x/none.cbz'), isNull);
    });

    test('getComicByTitle is exact match', () async {
      final id = await insert(title: 'One Piece');
      expect((await db.getComicByTitle('One Piece'))!.id, id);
      expect(await db.getComicByTitle('One'), isNull);
    });

    test('getComicByTitle returns first when duplicates exist', () async {
      final id = await insert(title: 'Dup');
      await insert(title: 'Dup');
      expect((await db.getComicByTitle('Dup'))!.id, id);
    });
  });

  group('updates', () {
    test('updateBookmark updates only currentPage', () async {
      final id = await insert();
      await db.updateBookmark(id, 12);
      final c = (await db.getComicByTitle('Comic'))!;
      expect(c.currentReadPage, 12);
      expect(c.totalPages, 10);
    });

    test('updateBookmark on unknown id is a no-op', () async {
      await insert();
      await db.updateBookmark(9999, 3);
      expect((await db.fetchAllComics()).single.currentReadPage, 0);
    });

    test('updateComic updates only provided fields', () async {
      final id = await insert(title: 'Old', author: 'A');
      await db.updateComic(
        id: id,
        title: 'New',
        isReading: true,
        totalPages: 33,
        picture: 'p.jpg',
        imagesPath: '/imgs/new',
        filePath: '/new.cbz',
        genre: 'G',
        collection: 'C',
        comicType: 'Manga',
      );
      final c = (await db.fetchAllComics()).single;
      expect(c.title, 'New');
      expect(c.isReading, isTrue);
      expect(c.isCompleted, isFalse);
      expect(c.totalPages, 33);
      expect(c.picture, 'p.jpg');
      expect(c.imagesPath, '/imgs/new');
      expect(c.filePath, '/new.cbz');
      expect(c.author, 'A');
      expect(c.genre, 'G');
      expect(c.collection, 'C');
      expect(c.comicType, 'Manga');
    });

    test('updateComic trims title and categories, ignores a blank title',
        () async {
      final id = await insert(title: 'Old');
      await db.updateComic(
          id: id, title: ' New ', author: ' Oda', genre: 'G ', collection: ' C ');
      var c = (await db.fetchAllComics()).single;
      expect(c.title, 'New');
      expect(c.author, 'Oda');
      expect(c.genre, 'G');
      expect(c.collection, 'C');

      await db.updateComic(id: id, title: '   ');
      c = (await db.fetchAllComics()).single;
      expect(c.title, 'New');
    });

    test('updateComic can set booleans back to false', () async {
      final id = await insert();
      await db.updateComic(id: id, isReading: true, isCompleted: true);
      await db.updateComic(id: id, isReading: false, isCompleted: false);
      final c = (await db.fetchAllComics()).single;
      expect(c.isReading, isFalse);
      expect(c.isCompleted, isFalse);
    });

    test('updateComic with no fields does nothing (no error)', () async {
      final id = await insert(title: 'Same');
      await db.updateComic(id: id);
      expect((await db.fetchAllComics()).single.title, 'Same');
    });

    test('updateComic cannot clear a nullable field (null means "skip")',
        () async {
      final id = await insert(author: 'A');
      await db.updateComic(id: id, author: null);
      expect((await db.fetchAllComics()).single.author, 'A');
    });

    test('deleteComic removes only the given row', () async {
      final id1 = await insert(title: 'A');
      await insert(title: 'B');
      await db.deleteComic(id1);
      expect((await db.fetchAllComics()).map((c) => c.title), ['B']);
    });

    test('deleteComic on unknown id is a no-op', () async {
      await insert();
      await db.deleteComic(12345);
      expect(await db.fetchAllComics(), hasLength(1));
    });
  });

  group('categories', () {
    // Category queries must compare with `!= ''`: a double-quoted "" is an
    // identifier in SQLite and fails with `no such column` on strict builds
    // such as the one bundled with sqflite_common_ffi.

    setUp(() async {
      await insert(title: 'Z', author: 'Oda', genre: 'Shonen', collection: 'OP', picture: 'b.jpg');
      await insert(title: 'A', author: 'Oda', genre: 'Shonen', collection: 'OP', picture: 'a.jpg');
      await insert(title: 'M', author: 'Miura', genre: 'Seinen');
      await insert(title: 'N', author: '', genre: null);
      await insert(title: 'O');
    });

    test('category queries run on strict SQLite (no double-quoted literals)',
        () async {
      await expectLater(db.getDistinctValues(ComicFields.author), completes);
    });

    test('getDistinctValues returns sorted distinct non-empty values',
        () async {
      expect(await db.getDistinctValues(ComicFields.author), ['Miura', 'Oda']);
      expect(await db.getDistinctValues(ComicFields.genre), ['Seinen', 'Shonen']);
      expect(await db.getDistinctValues(ComicFields.collection), ['OP']);
    });

    test('getAuthorsWithCount groups, counts, sorts and picks MIN picture',
        () async {
      final rows = await db.getAuthorsWithCount();
      expect(rows, [
        {'name': 'Miura', 'count': 1, 'coverPath': null}, // no cover -> null, not ''
        {'name': 'Oda', 'count': 2, 'coverPath': 'a.jpg'},
      ]);
    });

    test('getGenresWithCount', () async {
      final rows = await db.getGenresWithCount();
      expect(rows.map((r) => [r['name'], r['count']]), [
        ['Seinen', 1],
        ['Shonen', 2],
      ]);
    });

    test('getCollectionsWithCount', () async {
      final rows = await db.getCollectionsWithCount();
      expect(rows, [
        {'name': 'OP', 'count': 2, 'coverPath': 'a.jpg'},
      ]);
    });

    test('rename to an existing name merges the categories (counts)',
        () async {
      await db.updateAuthorName('Miura', 'Oda');
      final rows = await db.getAuthorsWithCount();
      expect(rows.single['count'], 3);
    });

    test('categories ignore case and surrounding whitespace', () async {
      await insert(
          title: 'B', author: 'oda ', genre: ' shonen', collection: 'op');
      expect(await db.getDistinctValues(ComicFields.author), ['Miura', 'Oda']);
      expect(
          await db.getDistinctValues(ComicFields.genre), ['Seinen', 'Shonen']);
      expect(await db.getDistinctValues(ComicFields.collection), ['OP']);

      final authors = await db.getAuthorsWithCount();
      expect(authors.map((r) => [r['name'], r['count']]), [
        ['Miura', 1],
        ['Oda', 3],
      ]);
      expect((await db.getGenresWithCount()).last['count'], 3);
      expect((await db.getCollectionsWithCount()).single['count'], 3);

      expect((await db.getComicsByAuthor(' ODA')).map((c) => c.title),
          ['A', 'B', 'Z']);
      expect(await db.getComicsByGenre('SHONEN '), hasLength(3));
      expect(await db.getComicsByCollection('Op'), hasLength(3));
    });

    test('categories are sorted case-insensitively', () async {
      await insert(title: 'x', author: 'akira');
      expect(await db.getDistinctValues(ComicFields.author),
          ['akira', 'Miura', 'Oda']);
      expect((await db.getAuthorsWithCount()).map((r) => r['name']),
          ['akira', 'Miura', 'Oda']);
    });

    test('getDistinctValues only accepts category columns', () async {
      expect(() => db.getDistinctValues(ComicFields.title),
          throwsArgumentError);
    });

    test('rename matches every spelling of the category and trims', () async {
      await insert(title: 'B', author: 'ODA');
      await db.updateAuthorName(' oda', ' Eiichiro Oda ');
      expect(await db.getDistinctValues(ComicFields.author),
          ['Eiichiro Oda', 'Miura']);
      expect(await db.getComicsByAuthor('Eiichiro Oda'), hasLength(3));

      await db.updateGenreName('SHONEN', 'Shōnen');
      await db.updateCollectionName('op', 'One Piece');
      expect(
          await db.getDistinctValues(ComicFields.genre), ['Seinen', 'Shōnen']);
      expect(await db.getDistinctValues(ComicFields.collection), ['One Piece']);
    });

    test('getComicsBy* filter and order by title', () async {
      expect((await db.getComicsByAuthor('Oda')).map((c) => c.title), ['A', 'Z']);
      expect((await db.getComicsByGenre('Seinen')).map((c) => c.title), ['M']);
      expect((await db.getComicsByCollection('OP')).map((c) => c.title), ['A', 'Z']);
      expect(await db.getComicsByAuthor('Nobody'), isEmpty);
      expect(await db.getComicsByAuthor(''), hasLength(1));
    });

    test('rename author / genre / collection', () async {
      await db.updateAuthorName('Oda', 'Eiichiro Oda');
      await db.updateGenreName('Shonen', 'Shōnen');
      await db.updateCollectionName('OP', 'One Piece');

      expect(await db.getComicsByAuthor('Oda'), isEmpty);
      expect((await db.getComicsByAuthor('Eiichiro Oda')).map((c) => c.title),
          ['A', 'Z']);
      expect(await db.getComicsByGenre('Shonen'), isEmpty);
      expect(await db.getComicsByGenre('Shōnen'), hasLength(2));
      expect(await db.getComicsByCollection('OP'), isEmpty);
      expect(await db.getComicsByCollection('One Piece'), hasLength(2));
      // Other categories untouched.
      expect(await db.getComicsByAuthor('Miura'), hasLength(1));
    });

    test('rename to an existing name merges the categories', () async {
      await db.updateAuthorName('Miura', 'Oda');
      expect(await db.getComicsByAuthor('Oda'), hasLength(3));
      expect(await db.getComicsByAuthor('Miura'), isEmpty);
    });

    test('rename of a non-existing name is a no-op', () async {
      await db.updateAuthorName('Ghost', 'X');
      expect(await db.getComicsByAuthor('X'), isEmpty);
      expect(await db.getComicsByAuthor('Oda'), hasLength(2));
    });
  });
}
