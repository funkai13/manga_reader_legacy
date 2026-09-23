import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/archive_builder.dart';
import '../../../../helpers/sqflite_test_setup.dart';

/// The very first v1 schema (initial commit), as found on a real device:
/// `id` instead of `_id`, no imagesPath and no flag columns. The v1 -> v2
/// migration used to assume the later 14-column v1 and failed on it, leaving
/// the app unable to open its database.
void main() {
  late Directory dbDir;

  setUpAll(() async {
    dbDir = createTempDir('comic_db_v1_original_');
    await setUpSqfliteFfi(dbDir);

    final legacy = await databaseFactory.openDatabase(
      p.join(dbDir.path, 'comics.db'),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE comics (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              filePath TEXT NOT NULL,
              title TEXT NOT NULL,
              picture TEXT,
              currentPage INTEGER NOT NULL,
              totalPages INTEGER NOT NULL,
              lastOpened INTEGER NOT NULL,
              currentReading INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
    await legacy.insert('comics', {
      'id': 7,
      'filePath': '/c/akira.cbz',
      'title': 'akira.cbz',
      'picture': '/i/akira/0001.jpg',
      'currentPage': 12,
      'totalPages': 180,
      'lastOpened': '2024-11-19T19:28:20.000',
      'currentReading': 1,
    });
    await legacy.close();
  });

  tearDownAll(() async {
    await (await ComicDatabase.instance.database).close();
    deleteQuietly(dbDir);
  });

  test('upgrades the original v1 schema keeping ids and reading progress',
      () async {
    final database = await ComicDatabase.instance.database;
    expect(await database.getVersion(), 3);

    final comic = (await ComicDatabase.instance.fetchAllComics()).single;
    expect(comic.id, 7);
    expect(comic.title, 'akira.cbz');
    expect(comic.filePath, '/c/akira.cbz');
    expect(comic.picture, '/i/akira/0001.jpg');
    expect(comic.currentReadPage, 12);
    expect(comic.totalPages, 180);
    expect(comic.lastOpened, '2024-11-19T19:28:20.000');
    expect(comic.imagesPath, '');
    expect(comic.isReading, isFalse);
    expect(comic.isFavorite, isFalse);
    expect(comic.isCompleted, isFalse);
    expect(comic.bookMarks, '');
    expect(comic.author, isNull);
  });

  test('the upgraded table accepts new rows', () async {
    final db = await ComicDatabase.instance.database;
    final id = await db.insert('comics', {
      'filePath': '/c/new.cbz',
      'title': 'new.cbz',
      'imagesPath': 'comics/c_1',
    });
    expect(id, greaterThan(7));
  });
}
