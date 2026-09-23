import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manga_reader/feature/Home/domain/entity/comic.dart';
import 'package:manga_reader/feature/Home/presenter/widgets/comic_card.dart';
import 'package:manga_reader/feature/Library/presenter/screens/filtered_comics_screen.dart';
import 'package:manga_reader/feature/Library/presenter/screens/library_screen.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/category_card.dart';
import 'package:manga_reader/feature/Library/presenter/widgets/comic_grid_widget.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/widget/fakes.dart';
import '../../helpers/widget/pump_app.dart';

void main() {
  setUpAll(registerTestFallbacks);

  group('LibraryScreen', () {
    Future<(MockComicRepository, MockLibraryRepository)> pumpLibrary(
      WidgetTester tester, {
      Size size = kPhoneSize,
      MockComicRepository? comicRepo,
      MockLibraryRepository? libraryRepo,
    }) async {
      final comics = comicRepo ?? createComicRepository(comics: sampleComics());
      final library = libraryRepo ?? createLibraryRepository();
      await pumpApp(
        tester,
        const LibraryScreen(),
        size: size,
        overrides:
            testOverrides(comicRepository: comics, libraryRepository: library),
      );
      await tester.pumpAndSettle();
      return (comics, library);
    }

    testWidgets('phone layout uses LibraryScreenMobile with 2 columns',
        (tester) async {
      await pumpLibrary(tester);
      expect(find.byType(LibraryScreenMobile), findsOneWidget);
      expect(find.text('Biblioteca'), findsOneWidget);
      for (final tab in ['Todos', 'Autores', 'Géneros', 'Colecciones']) {
        expect(find.text(tab), findsOneWidget);
      }
      expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isTrue);

      final grid = tester.widget<ComicGridWidget>(find.byType(ComicGridWidget));
      expect(grid.crossAxisCount, 2);
      expect(grid.scale, 1.0);
      expect(find.byType(ComicCard), findsWidgets);
    });

    testWidgets('tablet layout uses LibraryScreenTablet with 3 columns',
        (tester) async {
      await pumpLibrary(tester, size: kTabletSize);
      expect(find.byType(LibraryScreenTablet), findsOneWidget);
      expect(tester.widget<TabBar>(find.byType(TabBar)).isScrollable, isFalse);

      final grid = tester.widget<ComicGridWidget>(find.byType(ComicGridWidget));
      expect(grid.crossAxisCount, 3);
      expect(grid.scale, 0.8);
      expect(find.byType(ComicCard), findsNWidgets(4));
    });

    testWidgets('"Todos" shows a spinner while comics load', (tester) async {
      final repo =
          createComicRepository(getAll: () => neverCompletes<ComicEntity>());
      await pumpApp(tester, const LibraryScreen(),
          overrides: testOverrides(comicRepository: repo));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('"Todos" shows the error when comics fail', (tester) async {
      await pumpLibrary(tester,
          comicRepo:
              createComicRepository(getAll: () => Future.error('sin db')));
      expect(find.text('Error: sin db'), findsOneWidget);
    });

    testWidgets('"Todos" shows the empty message', (tester) async {
      await pumpLibrary(tester, comicRepo: createComicRepository(comics: []));
      expect(find.text('No hay cómics para mostrar'), findsOneWidget);
    });

    testWidgets('switching tabs loads each category type', (tester) async {
      final (_, library) = await pumpLibrary(tester);

      await tester.tap(find.text('Autores'));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryCard), findsNWidgets(3));
      verify(() => library.getAuthors()).called(1);

      await tester.tap(find.text('Géneros'));
      await tester.pumpAndSettle();
      verify(() => library.getGenres()).called(1);

      await tester.tap(find.text('Colecciones'));
      await tester.pumpAndSettle();
      verify(() => library.getCollections()).called(1);
      expect(find.byType(CategoryCard), findsNWidgets(3));
    });

    testWidgets('author → filtered comics → back', (tester) async {
      final (comics, _) = await pumpLibrary(tester);
      await tester.tap(find.text('Autores'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eiichiro Oda'));
      await tester.pumpAndSettle();
      expect(find.byType(FilteredComicsScreen), findsOneWidget);
      verify(() => comics.getComicsByAuthor('Eiichiro Oda')).called(1);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(FilteredComicsScreen), findsNothing);
      expect(find.text('Biblioteca'), findsOneWidget);
    });

    testWidgets('renaming a category refreshes the list', (tester) async {
      final (_, library) = await pumpLibrary(tester);
      await tester.tap(find.text('Autores'));
      await tester.pumpAndSettle();
      verify(() => library.getAuthors()).called(1);

      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'Oda Sensei');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      verify(() => library.renameAuthor('Eiichiro Oda', 'Oda Sensei'))
          .called(1);
      verify(() => library.getAuthors()).called(1);
      expect(find.text('Renombrado con éxito'), findsOneWidget);
    });
  });

  group('FilteredComicsScreen', () {
    Future<MockComicRepository> pumpFiltered(
      WidgetTester tester, {
      required String type,
      String value = 'X',
      MockComicRepository? repo,
    }) async {
      final comics = repo ?? createComicRepository(comics: sampleComics());
      await pumpApp(
        tester,
        FilteredComicsScreen(title: 'Filtro $value', type: type, value: value),
        overrides: testOverrides(comicRepository: comics),
      );
      return comics;
    }

    testWidgets('shows the title in the app bar', (tester) async {
      await pumpFiltered(tester, type: 'author', value: 'Oda');
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Filtro Oda'), findsOneWidget);
    });

    testWidgets('queries by author', (tester) async {
      final repo = await pumpFiltered(tester, type: 'author', value: 'Oda');
      await tester.pumpAndSettle();
      verify(() => repo.getComicsByAuthor('Oda')).called(1);
      expect(find.byType(ComicCard), findsWidgets);
    });

    testWidgets('queries by genre', (tester) async {
      final repo = await pumpFiltered(tester, type: 'genre', value: 'Shonen');
      await tester.pumpAndSettle();
      verify(() => repo.getComicsByGenre('Shonen')).called(1);
    });

    testWidgets('queries by collection', (tester) async {
      final repo =
          await pumpFiltered(tester, type: 'collection', value: 'One Piece');
      await tester.pumpAndSettle();
      verify(() => repo.getComicsByCollection('One Piece')).called(1);
    });

    testWidgets('unknown type shows the empty message', (tester) async {
      await pumpFiltered(tester, type: 'publisher');
      await tester.pumpAndSettle();
      expect(find.text('No hay cómics para mostrar'), findsOneWidget);
    });

    testWidgets('shows a spinner while loading', (tester) async {
      final repo = createComicRepository();
      when(() => repo.getComicsByGenre(any()))
          .thenAnswer((_) => neverCompletes<ComicEntity>());
      await pumpFiltered(tester, type: 'genre', repo: repo);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the error message', (tester) async {
      final repo = createComicRepository();
      when(() => repo.getComicsByGenre(any()))
          .thenAnswer((_) => Future.error('timeout'));
      await pumpFiltered(tester, type: 'genre', repo: repo);
      await tester.pumpAndSettle();
      expect(find.text('Error: timeout'), findsOneWidget);
    });

    testWidgets('uses scale 0.8 on tablets', (tester) async {
      final repo = createComicRepository(comics: sampleComics());
      await pumpApp(
        tester,
        const FilteredComicsScreen(title: 'T', type: 'author', value: 'Oda'),
        size: kTabletSize,
        overrides: testOverrides(comicRepository: repo),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<ComicGridWidget>(find.byType(ComicGridWidget)).scale,
          0.8);
    });
  });
}
