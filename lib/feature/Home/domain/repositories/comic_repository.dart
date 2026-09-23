import 'package:manga_reader/feature/Home/domain/entity/comic.dart';

abstract class ComicRepository {
  Future<ComicEntity> addComic(ComicEntity comic);

  Future<List<ComicEntity>> getAllComics();
  Future<ComicEntity?> getComicByPath(String path);
  Future<ComicEntity?> getComicByTitle(String title);
  Future<ComicEntity?> getComicByFilenameMatch(String filename);

  Future<void> addBookMark(int id, int bookMark);

  Future<void> startReadingComic(int id);

  Future<void> markCompleted(int id);

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
