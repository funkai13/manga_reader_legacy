import 'package:manga_reader/feature/Home/presenter/controller/comic_controller.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
import 'package:manga_reader/feature/Library/domain/providers/library_provider.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_controller.g.dart';

@riverpod
class LibraryController extends _$LibraryController {
  @override
  Future<List<CategoryEntity>> build(String type) async {
    final repository = ref.read(libraryRepositoryProvider);
    switch (type) {
      case 'author':
        return await repository.getAuthors();
      case 'genre':
        return await repository.getGenres();
      case 'collection':
        return await repository.getCollections();
      default:
        return [];
    }
  }

  /// Renames the category and refreshes every list that shows it: the
  /// categories, Home (comicControllerProvider) and the filtered lists.
  /// Repository errors are rethrown for the UI to report.
  Future<void> renameCategory(String oldName, String newName, String type) async {
    final repository = ref.read(libraryRepositoryProvider);
    switch (type) {
      case 'author':
        await repository.renameAuthor(oldName, newName);
        break;
      case 'genre':
        await repository.renameGenre(oldName, newName);
        break;
      case 'collection':
        await repository.renameCollection(oldName, newName);
        break;
    }
    if (!ref.mounted) return;
    ref.invalidateSelf();
    ref.invalidate(comicControllerProvider);
    ref.invalidate(filteredComicsProvider);
  }
}
