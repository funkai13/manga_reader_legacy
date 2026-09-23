import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/models/comic_fields.dart';

void main() {
  group('ComicFields', () {
    test('table name', () {
      expect(ComicFields.tableName, 'comics');
    });

    test('column names are stable (they are persisted in SQLite)', () {
      expect(ComicFields.id, '_id');
      expect(ComicFields.filePath, 'filePath');
      expect(ComicFields.title, 'title');
      expect(ComicFields.picture, 'picture');
      expect(ComicFields.currentPage, 'currentPage');
      expect(ComicFields.totalPages, 'totalPages');
      expect(ComicFields.lastOpened, 'lastOpened');
      expect(ComicFields.currentReading, 'currentReading');
      expect(ComicFields.imagesPath, 'imagesPath');
      expect(ComicFields.isReading, 'isReading');
      expect(ComicFields.isFavorite, 'isFavorite');
      expect(ComicFields.bookMarks, 'bookMarks');
      expect(ComicFields.rating, 'rating');
      expect(ComicFields.isCompleted, 'isCompleted');
      expect(ComicFields.author, 'author');
      expect(ComicFields.genre, 'genre');
      expect(ComicFields.collection, 'collection');
      expect(ComicFields.comicType, 'comicType');
    });

    test('column names are unique', () {
      final names = [
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
      ];
      expect(names.toSet().length, names.length);
    });

    test('SQL type definitions', () {
      expect(ComicFields.idType, 'INTEGER PRIMARY KEY AUTOINCREMENT');
      expect(ComicFields.textType, 'TEXT NOT NULL');
      expect(ComicFields.nullableTextType, 'TEXT');
      expect(ComicFields.intType, 'INTEGER NOT NULL');
      expect(ComicFields.nullableIntType, 'INTEGER');
      expect(ComicFields.booleanType, 'INTEGER NOT NULL DEFAULT 0');
    });
  });
}
