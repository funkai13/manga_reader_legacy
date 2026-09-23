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

/// Runs in its own isolate: seeds a v3 database (no contentHash, no indexes,
/// untrimmed categories) before the ComicDatabase singleton opens it, so
/// onUpgrade(3 -> 4) is exercised.
void main() {
  late Directory dbDir;
  final db = ComicDatabase.instance;

  setUpAll(() async {
    dbDir = createTempDir('comic_db_v3_');
    await setUpSqfliteFfi(dbDir);

    final legacy = await databaseFactory.openDatabase(
      p.join(dbDir.path, 'comics.db'),
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE comics (
              _id INTEGER PRIMARY KEY AUTOINCREMENT,
              filePath TEXT NOT NULL,
              title TEXT NOT NULL,
              picture TEXT,
              currentPage INTEGER NOT NULL DEFAULT 0,
              totalPages INTEGER NOT NULL DEFAULT 0,
              lastOpened TEXT,
              currentReading INTEGER NOT NULL DEFAULT 0,
              imagesPath TEXT NOT NULL,
              isReading INTEGER NOT NULL DEFAULT 0,
              isFavorite INTEGER NOT NULL DEFAULT 0,
              bookMarks TEXT DEFAULT '',
              rating INTEGER DEFAULT 0,
              isCompleted INTEGER NOT NULL DEFAULT 0,
              author TEXT,
              genre TEXT,
              collection TEXT,
              comicType TEXT
            )
          ''');
          await db.insert('comics', {
            'filePath': '/c/a.cbz',
            'title': ' a.cbz ',
            'imagesPath': 'comics/c_1',
            'currentPage': 7,
            'totalPages': 20,
            'isReading': 1,
            'author': 'Oda ',
            'genre': ' Shonen',
            'collection': 'One Piece',
            'comicType': 'Manga',
          });
          await db.insert('comics', {
            'filePath': '/c/b.cbz',
            'title': 'b.cbz',
            'imagesPath': 'comics/c_2',
            'author': 'oda',
            'genre': '   ',
            'collection': ' one piece ',
          });
        },
      ),
    );
    await legacy.close();
  });

  tearDownAll(() async {
    await (await db.database).close();
    deleteQuietly(dbDir);
  });

  test('upgrades v3 -> v4 keeping the data', () async {
    final database = await db.database;
    expect(await database.getVersion(), 4);

    final cols =
        (await database.rawQuery('PRAGMA table_info(${ComicFields.tableName})'))
            .map((c) => c['name'])
            .toSet();
    expect(cols, contains(ComicFields.contentHash));

    final a = (await db.fetchAllComics()).last;
    expect(a.currentReadPage, 7);
    expect(a.totalPages, 20);
    expect(a.isReading, isTrue);
    expect(a.comicType, 'Manga');
    expect(a.imagesPath, 'comics/c_1');
    expect(a.contentHash, isNull);
  });

  test('trims existing titles and categories', () async {
    final a = (await db.fetchAllComics()).last;
    expect(a.title, 'a.cbz');
    expect(a.author, 'Oda');
    expect(a.genre, 'Shonen');

    // 'Oda ' / 'oda' and 'One Piece' / ' one piece ' are one category each;
    // a blank genre is not a category.
    expect(await db.getDistinctValues(ComicFields.author), ['Oda']);
    expect((await db.getCollectionsWithCount()).single['count'], 2);
    expect(await db.getDistinctValues(ComicFields.genre), ['Shonen']);
  });

  test('creates the indexes, contentHash unique and NULL-tolerant', () async {
    final database = await db.database;
    final indexes = {
      for (final row in await database
          .rawQuery('PRAGMA index_list(${ComicFields.tableName})'))
        row['name'] as String: row['unique'] as int,
    };
    expect(indexes, {
      'idx_comics_author': 0,
      'idx_comics_genre': 0,
      'idx_comics_collection': 0,
      'idx_comics_filePath': 0,
      'idx_comics_contentHash': 1,
    });

    ComicModel withHash(String? hash) => ComicModel.fromMap({
          ...buildComicModel(id: null).toMap(),
          ComicFields.contentHash: hash,
        });
    await db.addComic(withHash('h1'));
    await db.addComic(withHash(null));
    await expectLater(db.addComic(withHash('h1')), throwsA(anything));
    expect(await db.fetchAllComics(), hasLength(4));
  });
}
