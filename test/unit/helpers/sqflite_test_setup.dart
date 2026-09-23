import 'dart:io';

import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configures sqflite to use FFI and stores databases in [dir].
///
/// ComicDatabase is a singleton that hardcodes `getDatabasesPath()/comics.db`
/// and caches the connection in a static field, so we redirect the databases
/// path to a per-test-file temp dir. Each test file runs in its own isolate,
/// so the singleton is fresh per file.
Future<void> setUpSqfliteFfi(Directory dir) async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
  await databaseFactory.setDatabasesPath(dir.path);
}

/// Removes every row from the comics table so tests stay independent.
Future<void> clearComicsTable() async {
  final db = await ComicDatabase.instance.database;
  await db.delete(ComicFields.tableName);
}
