import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/data/datasources/comic_database.dart';
import 'package:manga_reader/feature/Home/data/repositories/comic_repository_impl.dart';
import 'package:manga_reader/feature/Home/domain/provider/comic_provider.dart';
import 'package:manga_reader/feature/Library/data/repositories/library_repository_impl.dart';
import 'package:manga_reader/feature/Library/domain/providers/library_provider.dart';

void main() {
  test('comicRepositoryProvider wires ComicRepositoryImpl + singleton DB', () {
    final container = ProviderContainer.test();
    final repo = container.read(comicRepositoryProvider);
    expect(repo, isA<ComicRepositoryImpl>());
    expect((repo as ComicRepositoryImpl).datasource,
        same(ComicDatabase.instance));
  });

  test('libraryRepositoryProvider wires LibraryRepositoryImpl + singleton DB',
      () {
    final container = ProviderContainer.test();
    final repo = container.read(libraryRepositoryProvider);
    expect(repo, isA<LibraryRepositoryImpl>());
    expect((repo as LibraryRepositoryImpl).datasource,
        same(ComicDatabase.instance));
  });
}
