import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/domain/repositories/comic_repository.dart';
import 'package:manga_reader/feature/Home/data/services/comic_storage.dart';
import 'package:manga_reader/feature/Library/domain/repositories/library_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'comic_fixtures.dart';

class MockComicDatabase extends Mock implements ComicDatabase {}

class MockComicRepository extends Mock implements ComicRepository {}

class MockLibraryRepository extends Mock implements LibraryRepository {}

class MockComicStorage extends Mock implements ComicStorage {}


/// Registers fallback values needed by `any()` matchers.
void registerCommonFallbacks() {
  registerFallbackValue(buildComicModel());
  registerFallbackValue(buildComicEntity());
}
