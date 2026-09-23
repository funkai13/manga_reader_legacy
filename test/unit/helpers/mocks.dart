import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/domain/repositories/comic_file_repository.dart';
import 'package:manga_reader/feature/Home/domain/repositories/comic_repository.dart';
import 'package:manga_reader/feature/Library/domain/repositories/library_repository.dart';
import 'package:mocktail/mocktail.dart';

import 'comic_fixtures.dart';

class MockComicDatabase extends Mock implements ComicDatabase {}

class MockComicRepository extends Mock implements ComicRepository {}

class MockLibraryRepository extends Mock implements LibraryRepository {}

class MockComicFileRepository extends Mock implements ComicFileRepository {}

/// Registers fallback values needed by `any()` matchers.
void registerCommonFallbacks() {
  registerFallbackValue(buildComicModel());
  registerFallbackValue(buildComicEntity());
}
