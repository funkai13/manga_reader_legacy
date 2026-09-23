import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';
import 'package:sqflite/sqflite.dart';

import '../models/comic_model.dart';

class ComicDatabase {
  static final ComicDatabase instance = ComicDatabase._init();
  static Database? _database;

  ComicDatabase._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
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

  static const schemaVersion = 4;

  /// Metadata columns grouped as library categories. Their values are stored
  /// trimmed and compared case-insensitively ('Oda' == 'oda ').
  static const categoryColumns = [
    ComicFields.author,
    ComicFields.genre,
    ComicFields.collection,
  ];

  static const _textColumnsToTrim = [ComicFields.title, ...categoryColumns];

  Future<void> _createIndexes(DatabaseExecutor db) async {
    for (final column in categoryColumns) {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_comics_$column '
          'ON ${ComicFields.tableName} ($column COLLATE NOCASE)');
    }
    await db.execute('CREATE INDEX IF NOT EXISTS idx_comics_filePath '
        'ON ${ComicFields.tableName} (${ComicFields.filePath})');
    // UNIQUE still allows many NULLs: legacy rows have no hash.
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_comics_contentHash '
        'ON ${ComicFields.tableName} (${ComicFields.contentHash})');
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
        CREATE TABLE ${ComicFields.tableName} (
          ${ComicFields.id} ${ComicFields.idType},
          ${ComicFields.filePath} ${ComicFields.textType},
          ${ComicFields.title} ${ComicFields.textType},
          ${ComicFields.picture} ${ComicFields.nullableTextType},
          ${ComicFields.currentPage} ${ComicFields.intType} DEFAULT 0,
          ${ComicFields.totalPages} ${ComicFields.intType} DEFAULT 0,
          ${ComicFields.lastOpened} ${ComicFields.nullableTextType},
          ${ComicFields.currentReading} ${ComicFields.intType} DEFAULT 0,
          ${ComicFields.imagesPath} ${ComicFields.textType},
          ${ComicFields.isReading} ${ComicFields.booleanType},
          ${ComicFields.isFavorite} ${ComicFields.booleanType},
          ${ComicFields.bookMarks} ${ComicFields.nullableTextType} DEFAULT '',
          ${ComicFields.rating} ${ComicFields.nullableIntType} DEFAULT 0,
          ${ComicFields.isCompleted} ${ComicFields.booleanType},
          ${ComicFields.author} ${ComicFields.nullableTextType},
          ${ComicFields.genre} ${ComicFields.nullableTextType},
          ${ComicFields.collection} ${ComicFields.nullableTextType},
          ${ComicFields.comicType} ${ComicFields.nullableTextType},
          ${ComicFields.contentHash} ${ComicFields.nullableTextType}
        )
      ''');
    await _createIndexes(db);
  }

  Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // The v1 schema changed several times without a version bump: early
      // builds used `id` instead of `_id` and had no imagesPath or flag
      // columns. Copy whatever columns exist and default the rest.
      final columns =
          (await db.rawQuery('PRAGMA table_info(${ComicFields.tableName})'))
              .map((c) => c['name'] as String)
              .toSet();
      String orDefault(String column, String fallback) =>
          columns.contains(column) ? 'COALESCE($column, $fallback)' : fallback;
      String flag(String column) => columns.contains(column)
          ? "CASE WHEN $column = 'true' OR CAST($column AS INTEGER) > 0 "
              'THEN 1 ELSE 0 END'
          : '0';
      final idColumn = columns.contains(ComicFields.id)
          ? ComicFields.id
          : columns.contains('id')
              ? 'id'
              : 'NULL';
      String nullable(String column) =>
          columns.contains(column) ? column : 'NULL';

      await db.execute('''
          CREATE TABLE ${ComicFields.tableName}_new (
            ${ComicFields.id} ${ComicFields.idType},
            ${ComicFields.filePath} ${ComicFields.textType},
            ${ComicFields.title} ${ComicFields.textType},
            ${ComicFields.picture} ${ComicFields.nullableTextType},
            ${ComicFields.currentPage} ${ComicFields.intType} DEFAULT 0,
            ${ComicFields.totalPages} ${ComicFields.intType} DEFAULT 0,
            ${ComicFields.lastOpened} ${ComicFields.nullableTextType},
            ${ComicFields.currentReading} ${ComicFields.intType} DEFAULT 0,
            ${ComicFields.imagesPath} ${ComicFields.textType},
            ${ComicFields.isReading} ${ComicFields.booleanType},
            ${ComicFields.isFavorite} ${ComicFields.booleanType},
            ${ComicFields.bookMarks} ${ComicFields.nullableTextType} DEFAULT '',
            ${ComicFields.rating} ${ComicFields.nullableIntType} DEFAULT 0,
            ${ComicFields.isCompleted} ${ComicFields.booleanType}
          )
        ''');

      await db.execute('''
          INSERT INTO ${ComicFields.tableName}_new (
            ${ComicFields.id},
            ${ComicFields.filePath},
            ${ComicFields.title},
            ${ComicFields.picture},
            ${ComicFields.currentPage},
            ${ComicFields.totalPages},
            ${ComicFields.lastOpened},
            ${ComicFields.currentReading},
            ${ComicFields.imagesPath},
            ${ComicFields.isReading},
            ${ComicFields.isFavorite},
            ${ComicFields.bookMarks},
            ${ComicFields.rating},
            ${ComicFields.isCompleted}
          )
          SELECT
            $idColumn,
            ${orDefault(ComicFields.filePath, "''")},
            ${orDefault(ComicFields.title, "''")},
            ${nullable(ComicFields.picture)},
            ${orDefault(ComicFields.currentPage, '0')},
            ${orDefault(ComicFields.totalPages, '0')},
            ${nullable(ComicFields.lastOpened)},
            ${orDefault(ComicFields.currentReading, '0')},
            ${orDefault(ComicFields.imagesPath, "''")},
            ${flag(ComicFields.isReading)},
            ${flag(ComicFields.isFavorite)},
            ${orDefault(ComicFields.bookMarks, "''")},
            ${orDefault(ComicFields.rating, '0')},
            ${flag(ComicFields.isCompleted)}
          FROM ${ComicFields.tableName}
        ''');

      await db.execute('DROP TABLE ${ComicFields.tableName}');
      await db.execute(
          'ALTER TABLE ${ComicFields.tableName}_new RENAME TO ${ComicFields.tableName}');
    }

    if (oldVersion < 3) {
      try {
        await db.execute(
            'ALTER TABLE ${ComicFields.tableName} ADD COLUMN ${ComicFields.author} ${ComicFields.nullableTextType}');
        await db.execute(
            'ALTER TABLE ${ComicFields.tableName} ADD COLUMN ${ComicFields.genre} ${ComicFields.nullableTextType}');
        await db.execute(
            'ALTER TABLE ${ComicFields.tableName} ADD COLUMN ${ComicFields.collection} ${ComicFields.nullableTextType}');
        await db.execute(
            'ALTER TABLE ${ComicFields.tableName} ADD COLUMN ${ComicFields.comicType} ${ComicFields.nullableTextType}');
      } catch (e) {
        rethrow;
      }
    }

    if (oldVersion < 4) {
      await db.execute('ALTER TABLE ${ComicFields.tableName} '
          'ADD COLUMN ${ComicFields.contentHash} ${ComicFields.nullableTextType}');
      // Values are now stored trimmed; normalize what older builds wrote so
      // 'Oda' and 'Oda ' end up in the same category.
      for (final column in _textColumnsToTrim) {
        await db.execute('UPDATE ${ComicFields.tableName} '
            'SET $column = TRIM($column) '
            'WHERE $column IS NOT NULL AND $column != TRIM($column)');
      }
      await _createIndexes(db);
    }
  }

  /// Trims title and category values before they are written.
  static Map<String, Object?> _normalized(Map<String, Object?> values) => {
        for (final e in values.entries)
          e.key: _textColumnsToTrim.contains(e.key) && e.value is String
              ? (e.value as String).trim()
              : e.value,
      };

  Future<ComicModel?> _first(String where, List<Object?> args) async {
    final db = await database;
    final maps = await db.query(
      ComicFields.tableName,
      where: where,
      whereArgs: args,
      orderBy: '${ComicFields.id} ASC',
      limit: 1,
    );
    return maps.isEmpty ? null : ComicModel.fromMap(maps.first);
  }

  Future<ComicModel?> getComicByPath(String path) =>
      _first('${ComicFields.filePath} = ?', [path]);

  Future<ComicModel?> getComicById(int id) =>
      _first('${ComicFields.id} = ?', [id]);

  Future<ComicModel?> getComicByContentHash(String contentHash) =>
      _first('${ComicFields.contentHash} = ?', [contentHash]);

  /// Inserts the comic (title and categories trimmed). Throws a
  /// [DatabaseException] with a UNIQUE constraint error when a comic with the
  /// same contentHash already exists.
  Future<int> addComic(ComicModel comic) async {
    final db = await database;
    return await db.insert(ComicFields.tableName, _normalized(comic.toMap()));
  }

  /// Every comic, newest first (by insertion id), so the order is stable.
  Future<List<ComicModel>> fetchAllComics() async {
    final db = await database;
    final maps = await db.query(
      ComicFields.tableName,
      orderBy: '${ComicFields.id} DESC',
    );
    return List.generate(maps.length, (i) => ComicModel.fromMap(maps[i]));
  }

  Future<void> updateBookmark(int id, int currentPage) async {
    final db = await database;
    await db.update(
      ComicFields.tableName,
      {ComicFields.currentPage: currentPage},
      where: '${ComicFields.id} = ?',
      whereArgs: [id],
    );
  }

  /// Updates only the non-null arguments. Title and categories are trimmed;
  /// a title that is blank after trimming is ignored (titles can't be empty).
  Future<void> updateComic({
    required int id,
    String? imagesPath,
    String? picture,
    String? filePath,
    String? title,
    int? totalPages,
    bool? isReading,
    bool? isCompleted,
    String? author,
    String? genre,
    String? collection,
    String? comicType,
  }) async {
    final db = await database;
    final Map<String, Object?> values = {};

    if (imagesPath != null) values[ComicFields.imagesPath] = imagesPath;
    if (filePath != null) values[ComicFields.filePath] = filePath;
    if (title != null && title.trim().isNotEmpty) {
      values[ComicFields.title] = title;
    }
    if (picture != null) values[ComicFields.picture] = picture;
    if (totalPages != null) values[ComicFields.totalPages] = totalPages;
    if (isReading != null) {
      values[ComicFields.isReading] = isReading ? 1 : 0;
    }
    if (isCompleted != null) {
      values[ComicFields.isCompleted] = isCompleted ? 1 : 0;
    }
    if (author != null) values[ComicFields.author] = author;
    if (genre != null) values[ComicFields.genre] = genre;
    if (collection != null) values[ComicFields.collection] = collection;
    if (comicType != null) values[ComicFields.comicType] = comicType;

    if (values.isNotEmpty) {
      await db.update(
        ComicFields.tableName,
        _normalized(values),
        where: '${ComicFields.id} = ?',
        whereArgs: [id],
      );
    }
  }

  Future<ComicModel?> getComicByFilePath(String filePath) =>
      getComicByPath(filePath);

  Future<void> deleteComic(int id) async {
    final db = await database;
    await db.delete(
      ComicFields.tableName,
      where: '${ComicFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<ComicModel?> getComicByTitle(String title) =>
      _first('${ComicFields.title} = ?', [title]);

  // Category values are stored trimmed (on write and by the v4 migration),
  // so the queries below only need COLLATE NOCASE, which lets SQLite use the
  // `(column COLLATE NOCASE)` indexes.

  /// Distinct non-empty values of a category column, one per
  /// case-insensitive group, sorted case-insensitively. When spellings
  /// differ only in case the binary-smallest one wins ('Oda' over 'oda').
  Future<List<String>> getDistinctValues(String column) async {
    _checkCategoryColumn(column);
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT MIN($column) AS value
      FROM ${ComicFields.tableName}
      WHERE $column IS NOT NULL AND $column != ''
      GROUP BY $column COLLATE NOCASE
      ORDER BY value COLLATE NOCASE ASC
    ''');
    return maps.map((e) => e['value'] as String).toList();
  }

  static void _checkCategoryColumn(String column) {
    if (!categoryColumns.contains(column)) {
      throw ArgumentError.value(column, 'column', 'not a category column');
    }
  }

  /// Renames every comic whose [column] equals [oldName] ignoring case and
  /// surrounding whitespace. Renaming onto an existing name merges both.
  Future<void> _renameCategory(
      String column, String oldName, String newName) async {
    final db = await database;
    await db.update(
      ComicFields.tableName,
      {column: newName.trim()},
      where: '$column = ? COLLATE NOCASE',
      whereArgs: [oldName.trim()],
    );
  }

  Future<void> updateAuthorName(String oldName, String newName) =>
      _renameCategory(ComicFields.author, oldName, newName);

  Future<void> updateGenreName(String oldName, String newName) =>
      _renameCategory(ComicFields.genre, oldName, newName);

  Future<void> updateCollectionName(String oldName, String newName) =>
      _renameCategory(ComicFields.collection, oldName, newName);

  /// One row per case-insensitive category: name, comic count and the
  /// smallest non-empty cover path.
  Future<List<Map<String, dynamic>>> _categoriesWithCount(
      String column) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT MIN($column) as name, COUNT(*) as count, MIN(NULLIF(${ComicFields.picture}, '')) as coverPath
      FROM ${ComicFields.tableName}
      WHERE $column IS NOT NULL AND $column != ''
      GROUP BY $column COLLATE NOCASE
      ORDER BY name COLLATE NOCASE ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getAuthorsWithCount() =>
      _categoriesWithCount(ComicFields.author);

  Future<List<Map<String, dynamic>>> getGenresWithCount() =>
      _categoriesWithCount(ComicFields.genre);

  Future<List<Map<String, dynamic>>> getCollectionsWithCount() =>
      _categoriesWithCount(ComicFields.collection);

  Future<List<ComicModel>> _comicsInCategory(
      String column, String value) async {
    final db = await database;
    final result = await db.query(
      ComicFields.tableName,
      where: '$column = ? COLLATE NOCASE',
      whereArgs: [value.trim()],
      orderBy: '${ComicFields.title} COLLATE NOCASE ASC, ${ComicFields.id} ASC',
    );
    return result.map((json) => ComicModel.fromMap(json)).toList();
  }

  Future<List<ComicModel>> getComicsByAuthor(String author) =>
      _comicsInCategory(ComicFields.author, author);

  Future<List<ComicModel>> getComicsByGenre(String genre) =>
      _comicsInCategory(ComicFields.genre, genre);

  Future<List<ComicModel>> getComicsByCollection(String collection) =>
      _comicsInCategory(ComicFields.collection, collection);
}
