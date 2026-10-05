import '../feature/Home/domain/entity/comic.dart';
import 'reading_mode.dart';

class Comic {
  final int? id;
  final String title;
  final String filePath;
  final String imagesPath;
  final String? picture;
  final int currentPage;
  final int totalPages;
  final String? lastOpened;
  final bool isReading;
  final bool isCompleted;
  final bool isFavorite;
  final String? author;
  final String? genre;
  final String? collection;
  final ReadingMode comicType;
  final String? contentHash;
  final String? summary;
  final String? volume;
  final int fileSize;

  const Comic({
    this.id,
    required this.title,
    required this.filePath,
    required this.imagesPath,
    this.picture,
    this.currentPage = 0,
    this.totalPages = 0,
    this.lastOpened,
    this.isReading = false,
    this.isCompleted = false,
    this.isFavorite = false,
    this.author,
    this.genre,
    this.collection,
    this.comicType = ReadingMode.rightToLeft,
    this.contentHash,
    this.summary,
    this.volume,
    this.fileSize = 0,
  });

  double get progress => totalPages > 0 ? (currentPage + 1) / totalPages : 0.0;
  int get progressPercent => (progress * 100).clamp(0, 100).toInt();

  String get fileExtension {
    final dot = filePath.lastIndexOf('.');
    if (dot == -1 || dot == filePath.length - 1) return 'CBZ';
    return filePath.substring(dot + 1).toUpperCase();
  }

  String get formattedFileSize {
    if (fileSize <= 0) return '';
    if (fileSize >= 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (fileSize >= 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(fileSize / 1024).toStringAsFixed(0)} KB';
  }

  Comic copyWith({
    int? id,
    String? title,
    String? filePath,
    String? imagesPath,
    String? picture,
    int? currentPage,
    int? totalPages,
    String? lastOpened,
    bool? isReading,
    bool? isCompleted,
    bool? isFavorite,
    String? author,
    String? genre,
    String? collection,
    ReadingMode? comicType,
    String? contentHash,
    String? summary,
    String? volume,
    int? fileSize,
  }) {
    return Comic(
      id: id ?? this.id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      imagesPath: imagesPath ?? this.imagesPath,
      picture: picture ?? this.picture,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      lastOpened: lastOpened ?? this.lastOpened,
      isReading: isReading ?? this.isReading,
      isCompleted: isCompleted ?? this.isCompleted,
      isFavorite: isFavorite ?? this.isFavorite,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      collection: collection ?? this.collection,
      comicType: comicType ?? this.comicType,
      contentHash: contentHash ?? this.contentHash,
      summary: summary ?? this.summary,
      volume: volume ?? this.volume,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': id,
      'filePath': filePath,
      'title': title,
      'picture': picture,
      'currentPage': currentPage,
      'totalPages': totalPages,
      'lastOpened': lastOpened,
      'currentReading': isReading ? 1 : 0,
      'imagesPath': imagesPath,
      'isReading': isReading ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'isCompleted': isCompleted ? 1 : 0,
      'author': author,
      'genre': genre,
      'collection': collection,
      'comicType': comicType.code,
      'contentHash': contentHash,
      'summary': summary,
      'volume': volume,
      'fileSize': fileSize,
    };
  }

  factory Comic.fromMap(Map<String, dynamic> map) {
    return Comic(
      id: map['_id'] as int? ?? map['id'] as int?,
      title: map['title'] as String? ?? '',
      filePath: map['filePath'] as String? ?? '',
      imagesPath: map['imagesPath'] as String? ?? '',
      picture: map['picture'] as String?,
      currentPage: map['currentPage'] as int? ?? 0,
      totalPages: map['totalPages'] as int? ?? 0,
      lastOpened: map['lastOpened'] as String?,
      isReading: (map['isReading'] == 1 || map['isReading'] == true || map['currentReading'] == 1),
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
      author: map['author'] as String?,
      genre: map['genre'] as String?,
      collection: map['collection'] as String?,
      comicType: ReadingMode.fromCode(map['comicType'] as String?),
      contentHash: map['contentHash'] as String?,
      summary: map['summary'] as String?,
      volume: map['volume'] as String?,
      fileSize: map['fileSize'] as int? ?? 0,
    );
  }

  ComicEntity toEntity() {
    return ComicEntity(
      id: id,
      title: title,
      filePath: filePath,
      picture: picture ?? '',
      currentReadPage: currentPage,
      totalPages: totalPages,
      lastOpened: lastOpened ?? '',
      currentReading: isReading ? 1 : 0,
      imagesPath: imagesPath,
      isReading: isReading,
      isFavorite: isFavorite,
      bookMarks: '',
      isCompleted: isCompleted,
      author: author,
      genre: genre,
      collection: collection,
      comicType: comicType.code,
    );
  }

  factory Comic.fromEntity(ComicEntity entity) {
    return Comic(
      id: entity.id,
      title: entity.title,
      filePath: entity.filePath,
      picture: entity.picture.isEmpty ? null : entity.picture,
      currentPage: entity.currentReadPage,
      totalPages: entity.totalPages,
      lastOpened: entity.lastOpened.isEmpty ? null : entity.lastOpened,
      isReading: entity.isReading || entity.currentReading == 1,
      imagesPath: entity.imagesPath,
      isFavorite: entity.isFavorite,
      isCompleted: entity.isCompleted,
      author: entity.author,
      genre: entity.genre,
      collection: entity.collection,
      comicType: ReadingMode.fromCode(entity.comicType),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Comic &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath &&
          currentPage == other.currentPage &&
          totalPages == other.totalPages &&
          isReading == other.isReading &&
          isCompleted == other.isCompleted &&
          isFavorite == other.isFavorite &&
          title == other.title &&
          author == other.author &&
          genre == other.genre &&
          collection == other.collection &&
          comicType == other.comicType;

  @override
  int get hashCode =>
      id.hashCode ^
      filePath.hashCode ^
      currentPage.hashCode ^
      totalPages.hashCode ^
      title.hashCode;
}
