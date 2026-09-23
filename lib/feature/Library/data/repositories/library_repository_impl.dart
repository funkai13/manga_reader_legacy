import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/data/services/comic_storage.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
import 'package:manga_reader/feature/Library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  final ComicDatabase datasource;
  final ComicStorage storage;

  LibraryRepositoryImpl(this.datasource, {ComicStorage? storage})
      : storage = storage ?? ComicStorage();

  Future<List<CategoryEntity>> _toCategories(
    List<Map<String, dynamic>> rows,
    String type,
  ) =>
      Future.wait(rows.map((e) async => CategoryEntity(
            name: e['name'] as String,
            count: e['count'] as int,
            type: type,
            coverPath: await storage.resolveNullable(e['coverPath'] as String?),
          )));

  @override
  Future<List<CategoryEntity>> getAuthors() async {
    return _toCategories(await datasource.getAuthorsWithCount(), 'author');
  }

  @override
  Future<List<CategoryEntity>> getGenres() async {
    return _toCategories(await datasource.getGenresWithCount(), 'genre');
  }

  @override
  Future<List<CategoryEntity>> getCollections() async {
    return _toCategories(await datasource.getCollectionsWithCount(), 'collection');
  }

  @override
  Future<void> renameAuthor(String oldName, String newName) async {
    await datasource.updateAuthorName(oldName, newName);
  }

  @override
  Future<void> renameGenre(String oldName, String newName) async {
    await datasource.updateGenreName(oldName, newName);
  }

  @override
  Future<void> renameCollection(String oldName, String newName) async {
    await datasource.updateCollectionName(oldName, newName);
  }
}
