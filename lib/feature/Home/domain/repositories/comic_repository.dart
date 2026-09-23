import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

abstract class ComicRepository {
  /// Imports the archive at `comic.filePath`. Throws
  /// `DuplicateComicException` when a comic with the same content is already
  /// in the library, `UnsupportedComicException` for unreadable archives.
  Future<ComicEntity> addComic(ComicEntity comic);

  /// The comic already imported from a file with the same content as the one
  /// at [filePath] (whatever its name), or null.
  Future<ComicEntity?> findDuplicate(String filePath);

  Future<List<ComicEntity>> getAllComics();
  Future<ComicEntity?> getComicByPath(String path);
  Future<ComicEntity?> getComicByTitle(String title);

  Future<void> addBookMark(int id, int bookMark);

  Future<void> startReadingComic(int id);

  Future<void> markCompleted(int id);

  /// Deletes the comic and its extracted images.
  Future<void> deleteComic(int id);

  Future<void> updateComicMetadata({
    required int id,
    String? title,
    String? author,
    String? genre,
    String? collection,
    String? comicType,
  });

  Future<List<String>> getDistinctAuthors();
  Future<List<String>> getDistinctGenres();
  Future<List<String>> getDistinctCollections();

  Future<List<ComicEntity>> getComicsByAuthor(String author);
  Future<List<ComicEntity>> getComicsByGenre(String genre);
  Future<List<ComicEntity>> getComicsByCollection(String collection);
}
