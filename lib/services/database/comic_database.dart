import 'package:sqflite/sqflite.dart';
import '../../models/comic.dart';

class ComicDatabase {
  static final ComicDatabase instance = ComicDatabase._init();
  static Database? _database;

  ComicDatabase._init();

  static const String tableName = 'comics';
  static const int schemaVersion = 5;

  static const List<String> categoryColumns = ['author', 'genre', 'collection'];
  static const List<String> _textColumnsToTrim = ['title', ...categoryColumns];

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase('comics.db');
    return _database!;
  }

  Future<Database> _initDatabase(String filePath) async {
    final databasePath = await getDatabasesPath();
    final path = '$databasePath/$filePath';
    return await openDatabase(
      path,
      version: schemaVersion,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createIndexes(DatabaseExecutor db) async {
    for (final column in categoryColumns) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_comics_$column '
          'ON $tableName ($column COLLATE NOCASE)');
    }
    await db.execute('CREATE INDEX IF NOT EXISTS idx_comics_filePath '
        'ON $tableName (filePath)');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_comics_contentHash '
        'ON $tableName (contentHash)');
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        _id INTEGER PRIMARY KEY AUTOINCREMENT,
        filePath TEXT NOT NULL,
        title TEXT NOT NULL,
        picture TEXT,
        currentPage INTEGER DEFAULT 0,
        totalPages INTEGER DEFAULT 0,
        lastOpened TEXT,
        currentReading INTEGER DEFAULT 0,
        imagesPath TEXT NOT NULL,
        isReading INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        bookMarks TEXT DEFAULT '',
        rating INTEGER DEFAULT 0,
        isCompleted INTEGER DEFAULT 0,
        author TEXT,
        genre TEXT,
        collection TEXT,
        comicType TEXT,
        contentHash TEXT,
        summary TEXT,
        volume TEXT,
        fileSize INTEGER DEFAULT 0
      )
    ''');
    await _createIndexes(db);
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN author TEXT');
        await db.execute('ALTER TABLE $tableName ADD COLUMN genre TEXT');
        await db.execute('ALTER TABLE $tableName ADD COLUMN collection TEXT');
        await db.execute('ALTER TABLE $tableName ADD COLUMN comicType TEXT');
      } catch (_) {}
    }

    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN contentHash TEXT');
      } catch (_) {}
      for (final column in _textColumnsToTrim) {
        await db.execute('UPDATE $tableName '
            'SET $column = TRIM($column) '
            'WHERE $column IS NOT NULL AND $column != TRIM($column)');
      }
      await _createIndexes(db);
    }

    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN summary TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN volume TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableName ADD COLUMN fileSize INTEGER DEFAULT 0');
      } catch (_) {}
    }
  }

  static Map<String, Object?> _normalized(Map<String, Object?> values) => {
        for (final e in values.entries)
          e.key: _textColumnsToTrim.contains(e.key) && e.value is String
              ? (e.value as String).trim()
              : e.value,
      };

  Future<int> insertComic(Comic comic) async {
    final db = await database;
    return await db.insert(tableName, _normalized(comic.toMap()));
  }

  Future<List<Comic>> getAllComics() async {
    final db = await database;
    final maps = await db.query(tableName, orderBy: '_id DESC');
    return maps.map((map) => Comic.fromMap(map)).toList();
  }

  Future<Comic?> getComicById(int id) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: '_id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isEmpty ? null : Comic.fromMap(maps.first);
  }

  Future<Comic?> getComicByHash(String contentHash) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'contentHash = ?',
      whereArgs: [contentHash],
      limit: 1,
    );
    return maps.isEmpty ? null : Comic.fromMap(maps.first);
  }

  Future<Comic?> getComicByPath(String filePath) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'filePath = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    return maps.isEmpty ? null : Comic.fromMap(maps.first);
  }

  Future<void> updateComic(Comic comic) async {
    if (comic.id == null) return;
    final db = await database;
    await db.update(
      tableName,
      _normalized(comic.toMap()),
      where: '_id = ?',
      whereArgs: [comic.id],
    );
  }

  Future<void> updateProgress(
    int id,
    int currentPage, {
    bool? isReading,
    bool? isCompleted,
    String? lastOpened,
  }) async {
    final db = await database;
    final values = <String, Object?>{
      'currentPage': currentPage,
      if (isReading != null) 'isReading': isReading ? 1 : 0,
      if (isReading != null) 'currentReading': isReading ? 1 : 0,
      if (isCompleted != null) 'isCompleted': isCompleted ? 1 : 0,
      if (lastOpened != null) 'lastOpened': lastOpened,
    };
    await db.update(
      tableName,
      values,
      where: '_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setActiveReading(int id) async {
    final db = await database;
    // Mark others as not currentReading
    await db.update(tableName, {'currentReading': 0});
    await db.update(
      tableName,
      {
        'currentReading': 1,
        'isReading': 1,
        'lastOpened': DateTime.now().toIso8601String(),
      },
      where: '_id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteComic(int id) async {
    final db = await database;
    await db.delete(
      tableName,
      where: '_id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> _categoriesWithCount(String column) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT MIN($column) as name, COUNT(*) as count, MIN(NULLIF(picture, '')) as coverPath
      FROM $tableName
      WHERE $column IS NOT NULL AND $column != ''
      GROUP BY $column COLLATE NOCASE
      ORDER BY name COLLATE NOCASE ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getAuthorsWithCount() =>
      _categoriesWithCount('author');

  Future<List<Map<String, dynamic>>> getGenresWithCount() =>
      _categoriesWithCount('genre');

  Future<List<Map<String, dynamic>>> getCollectionsWithCount() =>
      _categoriesWithCount('collection');

  Future<List<Comic>> _comicsInCategory(String column, String value) async {
    final db = await database;
    final result = await db.query(
      tableName,
      where: '$column = ? COLLATE NOCASE',
      whereArgs: [value.trim()],
      orderBy: 'title COLLATE NOCASE ASC, _id ASC',
    );
    return result.map((json) => Comic.fromMap(json)).toList();
  }

  Future<List<Comic>> getComicsByAuthor(String author) =>
      _comicsInCategory('author', author);

  Future<List<Comic>> getComicsByGenre(String genre) =>
      _comicsInCategory('genre', genre);

  Future<List<Comic>> getComicsByCollection(String collection) =>
      _comicsInCategory('collection', collection);

  Future<void> renameCategory(String column, String oldName, String newName) async {
    final db = await database;
    await db.update(
      tableName,
      {column: newName.trim()},
      where: '$column = ? COLLATE NOCASE',
      whereArgs: [oldName.trim()],
    );
  }
}
