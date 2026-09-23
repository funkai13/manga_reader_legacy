import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
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
  }) {
    return db.addComic(buildComicModel(
      id: null,
      title: title,
      filePath: filePath,
      author: author,
      genre: genre,
      collection: collection,
      picture: picture,
      comicType: comicType,
    ));
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

    test('creates comics.db at version 3 with the full schema', () async {
      final database = await db.database;
      expect(p.normalize(database.path),
          p.normalize(p.join(dbDir.path, 'comics.db')));
      expect(await database.getVersion(), 3);

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
      });
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
      expect(all.map((c) => c.title), ['A', 'B']);
      final a = all.first;
      expect(a.id, id1);
      expect(a.author, 'Oda');
      expect(a.comicType, 'Manga');
      expect(a.isFavorite, isFalse);
      expect(a.rating, isNull);
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

    test('getComicByFilenameMatch matches path suffix after "/"', () async {
      final id = await insert(filePath: '/storage/emulated/0/one.cbz');
      expect((await db.getComicByFilenameMatch('one.cbz'))!.id, id);
      expect(await db.getComicByFilenameMatch('ne.cbz'), isNull);
      expect(await db.getComicByFilenameMatch('two.cbz'), isNull);
    });

    test(
      'getComicByFilenameMatch treats "_" and "%" in the filename literally',
      () async {
        await insert(filePath: '/c/myXcomic.cbz');
        expect(await db.getComicByFilenameMatch('my_comic.cbz'), isNull);
      },
      skip: 'BUG: getComicByFilenameMatch uses LIKE without escaping, so "_" '
          'and "%" in file names act as wildcards and produce false '
          'duplicate matches (e.g. "my_comic.cbz" matches "myXcomic.cbz").',
    );

    test(
      'getComicByFilenameMatch matches Windows-style paths',
      () async {
        await insert(filePath: r'C:\comics\one.cbz');
        expect(await db.getComicByFilenameMatch('one.cbz'), isNotNull);
      },
      skip: 'BUG: getComicByFilenameMatch only matches "%/<name>"; paths '
          r'using "\" separators (Windows desktop) are never detected.',
    );
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
