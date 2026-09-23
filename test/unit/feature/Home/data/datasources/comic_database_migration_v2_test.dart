import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/archive_builder.dart';
import '../../../../helpers/sqflite_test_setup.dart';

/// Runs in its own isolate: seeds a v2 database (no metadata columns) before
/// the ComicDatabase singleton opens it, so onUpgrade(2 -> 3) is exercised.
void main() {
  late Directory dbDir;

  setUpAll(() async {
    dbDir = createTempDir('comic_db_v2_');
    await setUpSqfliteFfi(dbDir);

    final legacy = await databaseFactory.openDatabase(
      p.join(dbDir.path, 'comics.db'),
      options: OpenDatabaseOptions(
        version: 2,
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
              isCompleted INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.insert('comics', {
            'filePath': '/c/x.cbz',
            'title': 'x',
            'imagesPath': '/i/x',
            'currentPage': 7,
            'totalPages': 20,
            'isReading': 1,
          });
        },
      ),
    );
    await legacy.close();
  });

  tearDownAll(() async {
    await (await ComicDatabase.instance.database).close();
    deleteQuietly(dbDir);
  });

  test('upgrades v2 -> v3 adding metadata columns and keeping progress',
      () async {
    final database = await ComicDatabase.instance.database;
    expect(await database.getVersion(), 3);

    final comic = (await ComicDatabase.instance.fetchAllComics()).single;
    expect(comic.title, 'x');
    expect(comic.currentReadPage, 7);
    expect(comic.totalPages, 20);
    expect(comic.isReading, isTrue);
    expect(comic.author, isNull);
    expect(comic.genre, isNull);
    expect(comic.collection, isNull);
    expect(comic.comicType, isNull);
  });
}
