class ComicFields {
  static const tableName = 'comics';

  static const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
  static const textType = 'TEXT NOT NULL';
  static const nullableTextType = 'TEXT';
  static const intType = 'INTEGER NOT NULL';
  static const nullableIntType = 'INTEGER';
  static const booleanType = 'INTEGER NOT NULL DEFAULT 0';

  static const id = '_id';
  static const filePath = 'filePath';
  static const title = 'title';
  static const picture = 'picture';
  static const currentPage = 'currentPage';
  static const totalPages = 'totalPages';
  static const lastOpened = 'lastOpened';
  static const currentReading = 'currentReading';
  static const imagesPath = 'imagesPath';
  static const isReading = 'isReading';
  static const isFavorite = 'isFavorite';
  static const bookMarks = 'bookMarks';
  static const rating = 'rating';
  static const isCompleted = 'isCompleted';
  static const author = 'author';
  static const genre = 'genre';
  static const collection = 'collection';
  static const comicType = 'comicType';

  /// Fingerprint of the source archive (see ComicFingerprint); NULL for
  /// rows imported before schema v4.
  static const contentHash = 'contentHash';
}
