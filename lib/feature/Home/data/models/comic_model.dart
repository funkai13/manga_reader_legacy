import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

import 'comic_fields.dart';

class ComicModel extends ComicEntity {
  ComicModel(
      {required super.title,
      required super.filePath,
      required super.totalPages,
      required super.lastOpened,
      required super.currentReading,
      required super.currentReadPage,
      required super.picture,
      required super.id,
      required super.imagesPath,
      required super.isFavorite,
      required super.isReading,
      required super.bookMarks,
      required super.isCompleted,
      required super.rating,
      super.author,
      super.genre,
      super.collection,
      super.comicType,
      this.contentHash});

  /// Fingerprint of the archive the comic was imported from. Only stored in
  /// the DB (duplicate detection); not part of [ComicEntity].
  final String? contentHash;

  Map<String, dynamic> toMap() {
    return {
      ComicFields.id: id,
      ComicFields.filePath: filePath,
      ComicFields.title: title,
      ComicFields.picture: picture,
      ComicFields.currentPage: currentReadPage,
      ComicFields.totalPages: totalPages,
      ComicFields.lastOpened: lastOpened,
      ComicFields.currentReading: currentReading,
      ComicFields.imagesPath: imagesPath,
      ComicFields.isFavorite: isFavorite ? 1 : 0,
      ComicFields.isReading: isReading ? 1 : 0,
      ComicFields.rating: rating,
      ComicFields.bookMarks: bookMarks,
      ComicFields.isCompleted: isCompleted ? 1 : 0,
      ComicFields.author: author,
      ComicFields.genre: genre,
      ComicFields.collection: collection,
      ComicFields.comicType: comicType,
      ComicFields.contentHash: contentHash,
    };
  }

  factory ComicModel.fromMap(Map<String, dynamic> map) {
    bool intToBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        return value == '1' || value.toLowerCase() == 'true';
      }
      return false;
    }

    int? toIntOrNull(dynamic value) {
      if (value == null) return null;
      if (value is int) return value == 0 ? null : value;
      if (value is String) {
        final parsed = int.tryParse(value);
        return parsed == 0 ? null : parsed;
      }
      return null;
    }

    return ComicModel(
        id: map[ComicFields.id] as int?,
        filePath: map[ComicFields.filePath] as String,
        title: map[ComicFields.title] as String,
        picture: map[ComicFields.picture] as String? ?? '',
        currentReadPage: map[ComicFields.currentPage] as int? ?? 0,
        totalPages: map[ComicFields.totalPages] as int? ?? 0,
        lastOpened: map[ComicFields.lastOpened] as String? ?? '',
        currentReading: map[ComicFields.currentReading] as int? ?? 0,
        imagesPath: map[ComicFields.imagesPath] as String,
        isFavorite: intToBool(map[ComicFields.isFavorite]),
        isReading: intToBool(map[ComicFields.isReading]),
        rating: toIntOrNull(map[ComicFields.rating]),
        bookMarks: map[ComicFields.bookMarks] as String? ?? '',
        isCompleted: intToBool(map[ComicFields.isCompleted]),
        author: map[ComicFields.author] as String?,
        genre: map[ComicFields.genre] as String?,
        collection: map[ComicFields.collection] as String?,
        comicType: map[ComicFields.comicType] as String?,
        contentHash: map[ComicFields.contentHash] as String?);
  }
}
