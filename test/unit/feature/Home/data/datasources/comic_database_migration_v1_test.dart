import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../helpers/archive_builder.dart';
import '../../../../helpers/sqflite_test_setup.dart';

/// Runs in its own isolate: seeds a legacy v1 database file *before* the
/// ComicDatabase singleton opens it, so onUpgrade(1 -> 3) is exercised.
void main() {
  late Directory dbDir;

  setUpAll(() async {
    dbDir = createTempDir('comic_db_v1_');
    await setUpSqfliteFfi(dbDir);

    final legacy = await databaseFactory.openDatabase(
      p.join(dbDir.path, 'comics.db'),
      options: OpenDatabaseOptions(
        version: 1,
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
              isReading TEXT,
              isFavorite INTEGER,
              bookMarks TEXT DEFAULT '',
              rating INTEGER DEFAULT 0,
              isCompleted TEXT
            )
          ''');
        },
      ),
    );
    Future<void> row(String title, Object? reading, Object? fav,
            Object? completed) =>
        legacy.insert('comics', {
          'filePath': '/c/$title.cbz',
          'title': title,
          'imagesPath': '/i/$title',
          'isReading': reading,
          'isFavorite': fav,
          'isCompleted': completed,
        });
    await row('a', 'true', 5, '1');
    await row('b', '0', 0, 'false');
    await row('c', '1', -3, 'true');
    await legacy.close();
  });

  tearDownAll(() async {
    await (await ComicDatabase.instance.database).close();
    deleteQuietly(dbDir);
  });

  test('upgrades a v1 database to v3 keeping rows and normalizing booleans',
      () async {
    final database = await ComicDatabase.instance.database;
    expect(await database.getVersion(), 3);

    final cols = (await database.rawQuery('PRAGMA table_info(comics)'))
        .map((c) => c['name'])
        .toSet();
    expect(
        cols,
        containsAll([
          ComicFields.author,
          ComicFields.genre,
          ComicFields.collection,
          ComicFields.comicType,
        ]));

    final comics = await ComicDatabase.instance.fetchAllComics();
    expect(comics.map((c) => c.title), ['a', 'b', 'c']);

    final a = comics[0];
    expect(a.isReading, isTrue);
    expect(a.isFavorite, isTrue);
    expect(a.isCompleted, isTrue);
    expect(a.author, isNull);
    expect(a.comicType, isNull);

    final b = comics[1];
    expect(b.isReading, isFalse);
    expect(b.isFavorite, isFalse);
    expect(b.isCompleted, isFalse);

    final c = comics[2];
    expect(c.isReading, isTrue);
    expect(c.isFavorite, isFalse, reason: 'negative favorite -> 0');
    expect(c.isCompleted, isTrue);

    final raw = await database.query('comics', orderBy: '_id');
    expect(raw.map((r) => r['isReading']), [1, 0, 1],
        reason: 'stored as INTEGER after upgrade');
  });

  test('new columns are writable after upgrade', () async {
    final db = ComicDatabase.instance;
    final a = (await db.getComicByTitle('a'))!;
    await db.updateComic(id: a.id!, author: 'Oda', comicType: 'Manga');
    final updated = (await db.getComicByTitle('a'))!;
    expect(updated.author, 'Oda');
    expect(updated.comicType, 'Manga');
  });
}
