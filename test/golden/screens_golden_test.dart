@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/screen/home_screen.dart';
import 'package:manga_reader/feature/Library/domain/entities/category_entity.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_grid_widget.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_list_widget.dart';

import '../helpers/widget/fakes.dart';
import '../helpers/widget/golden.dart';

void main() {
  late GoldenCovers covers;

  setUpAll(() async {
    registerTestFallbacks();
    covers = await GoldenCovers.create();
  });
  tearDownAll(() => covers.delete());

  List<ComicEntity> homeComics() => [
        ...sampleComics(picture: covers.pathFor),
        buildComic(
            id: 5,
            title: 'Dragon Ball Vol. 1',
            picture: covers.pathFor(5),
            isReading: true,
            currentReadPage: 20),
        buildComic(id: 6, title: 'Watchmen', picture: covers.pathFor(6)),
      ];

  List<CategoryEntity> categories(String type) => [
        CategoryEntity(
            name: 'Eiichiro Oda',
            count: 12,
            type: type,
            coverPath: covers.pathFor(1)),
        CategoryEntity(
            name: 'Frank Miller',
            count: 3,
            type: type,
            coverPath: covers.pathFor(2)),
        CategoryEntity(name: 'Katsuhiro Otomo', count: 6, type: type),
        CategoryEntity(
            name: 'Naoki Urasawa',
            count: 1,
            type: type,
            coverPath: covers.pathFor(4)),
      ];

  for (final variant in goldenVariants) {
    group('$variant', () {
      testWidgets('home_screen with comics', (tester) async {
        await covers.precache(tester);
        await pumpGolden(
          tester,
          const HomeScreen(),
          variant,
          overrides: testOverrides(
              comicRepository: createComicRepository(comics: homeComics())),
        );
        await expectGolden(
            find.byType(HomeScreen), variant.file('home_screen'));
      });

      testWidgets('home_screen empty', (tester) async {
        await pumpGolden(
          tester,
          const HomeScreen(),
          variant,
          overrides: testOverrides(comicRepository: createComicRepository()),
        );
        await tester.pump(const Duration(milliseconds: 150));
        await tester.pumpAndSettle();
        await expectGolden(
            find.byType(HomeScreen), variant.file('home_screen_empty'));
      });

      testWidgets('library_screen "Todos"', (tester) async {
        await covers.precache(tester);
        await pumpGolden(
          tester,
          const LibraryScreen(),
          variant,
          overrides: testOverrides(
              comicRepository: createComicRepository(comics: homeComics())),
        );
        await expectGolden(
            find.byType(LibraryScreen), variant.file('library_all'));
      });

      testWidgets('library category grid', (tester) async {
        await covers.precache(tester);
        await pumpGolden(
          tester,
          CategoryGridWidget(
              type: 'author', crossAxisCount: variant.isTablet ? 3 : 2),
          variant,
          wrapInScaffold: true,
          overrides: testOverrides(
            libraryRepository:
                createLibraryRepository(authors: categories('author')),
          ),
        );
        await expectGolden(
            find.byType(Scaffold), variant.file('library_category_grid'));
      });

      testWidgets('library category list', (tester) async {
        await pumpGolden(
          tester,
          const CategoryListWidget(type: 'genre'),
          variant,
          wrapInScaffold: true,
          overrides: testOverrides(
            libraryRepository:
                createLibraryRepository(genres: categories('genre')),
          ),
        );
        await expectGolden(
            find.byType(Scaffold), variant.file('library_category_list'));
      });
    });
  }
}
