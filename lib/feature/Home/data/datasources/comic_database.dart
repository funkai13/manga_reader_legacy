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
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
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
          ${ComicFields.comicType} ${ComicFields.nullableTextType}
        )
      ''');
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
  }

  Future<ComicModel?> getComicByPath(String path) async {
    final db = await database;
    final result = await db.query(
      ComicFields.tableName,
      where: '${ComicFields.filePath} = ?',
      whereArgs: [path],
    );

    if (result.isNotEmpty) {
      return ComicModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<ComicModel?> getComicByFilenameMatch(String filename) async {
    final db = await database;
    // Check if any filePath ends with the filename
    // We use LIKE with %/filename to match the end of the path
    final result = await db.query(
      ComicFields.tableName,
      where: '${ComicFields.filePath} LIKE ?',
      whereArgs: ['%/$filename'],
    );

    if (result.isNotEmpty) {
      return ComicModel.fromMap(result.first);
    } else {
      return null;
    }
  }

  Future<int> addComic(ComicModel comic) async {
    final db = await database;
    return await db.insert(ComicFields.tableName, comic.toMap());
  }

  Future<List<ComicModel>> fetchAllComics() async {
    final db = await database;
    final maps = await db.query(ComicFields.tableName);
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
    if (title != null) values[ComicFields.title] = title;
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
        values,
        where: '${ComicFields.id} = ?',
        whereArgs: [id],
      );
    }
  }

  Future<ComicModel?> getComicByFilePath(String filePath) async {
    final db = await database;
    final maps = await db.query(
      ComicFields.tableName,
      where: '${ComicFields.filePath} = ?',
      whereArgs: [filePath],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return ComicModel.fromMap(maps.first);
  }

  Future<void> deleteComic(int id) async {
    final db = await database;
    await db.delete(
      ComicFields.tableName,
      where: '${ComicFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<ComicModel?> getComicByTitle(String title) async {
    final db = await database;
    final maps = await db.query(
      ComicFields.tableName,
      where: '${ComicFields.title} = ?',
      whereArgs: [title],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return ComicModel.fromMap(maps.first);
  }

  Future<List<String>> getDistinctValues(String column) async {
    final db = await database;
    final maps = await db.query(
      ComicFields.tableName,
      columns: ['DISTINCT $column'],
      where: "$column IS NOT NULL AND $column != ''",
      orderBy: column,
    );
    return maps.map((e) => e[column] as String).toList();
  }

  Future<void> updateAuthorName(String oldName, String newName) async {
    final db = await database;
    await db.update(
      ComicFields.tableName,
      {ComicFields.author: newName},
      where: '${ComicFields.author} = ?',
      whereArgs: [oldName],
    );
  }

  Future<void> updateGenreName(String oldName, String newName) async {
    final db = await database;
    await db.update(
      ComicFields.tableName,
      {ComicFields.genre: newName},
      where: '${ComicFields.genre} = ?',
      whereArgs: [oldName],
    );
  }

  Future<void> updateCollectionName(String oldName, String newName) async {
    final db = await database;
    await db.update(
      ComicFields.tableName,
      {ComicFields.collection: newName},
      where: '${ComicFields.collection} = ?',
      whereArgs: [oldName],
    );
  }

  Future<List<Map<String, dynamic>>> getAuthorsWithCount() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ${ComicFields.author} as name, COUNT(*) as count, MIN(NULLIF(${ComicFields.picture}, '')) as coverPath
      FROM ${ComicFields.tableName}
      WHERE ${ComicFields.author} IS NOT NULL AND ${ComicFields.author} != ''
      GROUP BY ${ComicFields.author}
      ORDER BY ${ComicFields.author} ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getGenresWithCount() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ${ComicFields.genre} as name, COUNT(*) as count, MIN(NULLIF(${ComicFields.picture}, '')) as coverPath
      FROM ${ComicFields.tableName}
      WHERE ${ComicFields.genre} IS NOT NULL AND ${ComicFields.genre} != ''
      GROUP BY ${ComicFields.genre}
      ORDER BY ${ComicFields.genre} ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> getCollectionsWithCount() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT ${ComicFields.collection} as name, COUNT(*) as count, MIN(NULLIF(${ComicFields.picture}, '')) as coverPath
      FROM ${ComicFields.tableName}
      WHERE ${ComicFields.collection} IS NOT NULL AND ${ComicFields.collection} != ''
      GROUP BY ${ComicFields.collection}
      ORDER BY ${ComicFields.collection} ASC
    ''');
  }

  Future<List<ComicModel>> getComicsByAuthor(String author) async {
    final db = await database;
    final result = await db.query(
      ComicFields.tableName,
      where: '${ComicFields.author} = ?',
      whereArgs: [author],
      orderBy: '${ComicFields.title} ASC',
    );
    return result.map((json) => ComicModel.fromMap(json)).toList();
  }

  Future<List<ComicModel>> getComicsByGenre(String genre) async {
    final db = await database;
    final result = await db.query(
      ComicFields.tableName,
      where: '${ComicFields.genre} = ?',
      whereArgs: [genre],
      orderBy: '${ComicFields.title} ASC',
    );
    return result.map((json) => ComicModel.fromMap(json)).toList();
  }

  Future<List<ComicModel>> getComicsByCollection(String collection) async {
    final db = await database;
    final result = await db.query(
      ComicFields.tableName,
      where: '${ComicFields.collection} = ?',
      whereArgs: [collection],
      orderBy: '${ComicFields.title} ASC',
    );
    return result.map((json) => ComicModel.fromMap(json)).toList();
  }
}
